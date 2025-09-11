defmodule MaxGallery.Context do
  alias MaxGallery.Storage
  alias MaxGallery.Cache
  alias MaxGallery.Core.Cypher
  alias MaxGallery.Core.Cypher.Api, as: CypherApi
  alias MaxGallery.Core.Group
  alias MaxGallery.Core.Group.Api, as: GroupApi
  alias MaxGallery.Core.User.Api, as: UserApi
  alias MaxGallery.Encrypter
  alias MaxGallery.Phantom
  alias MaxGallery.Utils
  alias MaxGallery.Variables
  alias MaxGallery.Validate
  alias MaxGallery.Repo
  @type querry :: [%Cypher{} | %Group{} | map()]
  @type response :: {:ok, querry()} | {:error, String.t()}

  @moduledoc """
    This module serves as the context layer for managing encrypted files and groups
    within the MaxGallery system.

    It provides high-level functions for:

    - Inserting, updating, deleting, and duplicating encrypted files and groups;
    - Retrieving encrypted data individually or in bulk;
    - Managing hierarchical group structures;
    - Zipping files or entire group trees;
    - Updating encryption keys across all stored records;
    - Performing cascading deletions safely and recursively.

    Internally, it interacts with:

    - `MaxGallery.Core.Cypher.Api` for file entries;
    - `MaxGallery.Core.Group.Api` for group entities;
    - `MaxGallery.Encrypter` for encryption/decryption;
    - `MaxGallery.Phantom` for validation and metadata;
    - `MaxGallery.Utils` for utilities such as tree traversal and zip generation.

  All operations require a valid encryption key to ensure security and integrity.
  """

  @doc """
  Encrypts and inserts a file into the system, storing both its encrypted contents and metadata.

  ## Parameters

    - `path` (string): The local file path of the file to be encrypted and inserted.
    - `key` (binary/string): The encryption key used to encrypt the filename and file content.
    - `opts` (keyword list, optional):
      - `:name` (string) — an optional name to override the file's name extracted from `path`.
      - `:group` (string) — an optional group ID (binary ID) to associate the file with.

  ## Process

  The function:
    - Extracts the file extension.
    - Encrypts the file name (or override name if provided).
    - Encrypts the file content.
    - Uploads the encrypted content to a binary bucket.
    - Stores the encrypted file metadata and group association in the MongoDB database.

  ## Returns

    - `{:ok, id}`: The inserted file's binary ID (`_id`) as a string on success.
    - `{:error, reason}`: If any step fails (e.g., encryption, upload, or database insert).

  ## Security

  Requires a valid encryption key and passes a `Phantom.insert_line?/1` validation check.
  """
  @spec cypher_insert(path :: Path.t(), user :: binary(), key :: String.t(), opts :: Keyword.t()) ::
          response()
  def cypher_insert(path, user, key, opts \\ []) do
    name = Keyword.get(opts, :name)

    group =
      Keyword.get(opts, :group)

    ext =
      if name do
        Path.extname(name)
      else
        Path.extname(path)
      end

    ext =
      if ext == "" do
        ".txt"
      else
        ext
      end

    {name_iv, name} =
      if name do
        Path.basename(name, ext)
        |> Encrypter.encrypt(key)
      else
        Path.basename(path, ext)
        |> Encrypter.encrypt(key)
      end

    with true <- Phantom.insert_line?(user, key),
         size <- File.stat!(path) |> Map.fetch!(:size),
         Utils.check_limit(user, size),
         {stream, blob_iv} <- Encrypter.encrypt_stream(path, key),
         {msg_iv, msg} <- Encrypter.encrypt(Phantom.get_text(), key),
         {:ok, _querry} <- UserApi.exists(user),
         {:ok, querry} <-
           CypherApi.insert(%{
             user_id: user,
             name_iv: name_iv,
             name: name,
             blob_iv: blob_iv,
             ext: ext,
             msg: msg,
             msg_iv: msg_iv,
             length: size,
             group_id: group
           }),
         :ok <- Storage.put_stream(user, querry.id, stream, true) do
      {:ok, querry.id}
    else
      false ->
        {:error, "invalid key/user"}

      error ->
        error
    end
  end

  ## Private recursive function to return the already encrypted data of each date/group to be stored in the database.
  @spec send_package(item :: map(), user :: binary(), lazy? :: boolean(), memory? :: boolean(), key :: String.t()) :: querry()
  defp send_package(%{ext: _ext} = item, user, lazy?, memory?, key) do
    name = Encrypter.decrypt(item.name, item.iv, key)

    if lazy? do
      %{
        name: name,
        ext: item.ext,
        id: item.id,
        group: item.group_id
      }
    else
      if memory? do
        # Return blob in memory using new cache system
        blob = Cache.get_content(user, item.id, item.blob_iv, key)

        %{
          name: name,
          blob: blob,
          ext: item.ext,
          id: item.id,
          group: item.group_id
        }
      else
        # Return file path using cache system
        {path, _downloaded} = Cache.consume_cache(user, item.id, item.blob_iv, key)

        %{
          name: name,
          path: path,
          ext: item.ext,
          id: item.id,
          group: item.group_id
        }
      end
    end
    |> Phantom.encode_bin()
  end

  defp send_package(item, _user, _lazy, _memory, key) do
    name = Encrypter.decrypt(item.name, item.name_iv, key)
    %{name: name, id: item.id, group: item.group_id} |> Phantom.encode_bin()
  end

  @doc """
  Decrypts and returns all items (files and/or subgroups) from a specific group.

  ## Parameters

    - `key` (binary/string): The encryption key used to decrypt file and group metadata.
    - `opts` (keyword list, optional):
      - `:lazy` (boolean) — If `true`, returns only basic metadata (e.g. name, ext, id); skips blob download/decryption.
      - `:only` (list) — A list of filters to selectively include only certain types (e.g., `[:files]`, `[:groups]`).
      - `:group` (string) — The group ID (binary ID) from which to retrieve contents. If not provided, retrieves the top-level group.


  ## Behavior

  - Retrieves all items from the specified group using `Utils.get_group/2`.
  - Decrypts each item's metadata (and optionally its content if `lazy?` is false).
  - Encodes the full result using `Phantom.encode_bin/1`.

  ## Returns

    - `{:ok, binary}`: A binary-encoded list of decrypted items.
  """
  @spec decrypt_all(user :: binary(), key :: String.t(), opts :: Keyword.t()) :: {:ok, querry()}
  def decrypt_all(user, key, opts \\ []) do
    lazy? = Keyword.get(opts, :lazy)
    only = Keyword.get(opts, :only)
    memory? = Keyword.get(opts, :memory)
    group_id = Keyword.get(opts, :group)

    {:ok, contents} = Utils.get_group(user, group_id, only: only)

    querry =
      for item <- contents do
        send_package(item, user, lazy?, memory?, key)
      end

    {:ok, querry}
  end

  @doc """
  Deletes an encrypted file and optionally its associated binary data from storage.

  ## Parameters

    - `id` (string): The binary ID of the file to delete.
    - `key` (binary/string): The encryption key used to validate access to the file.
    - `opts` (keyword list, optional):
      - `:shallow` (boolean) — If `true`, only removes the database entry; skips deleting the binary content.

  ## Behavior

  - Retrieves the file by its ID using `Core.Cypher.Api.get/1`.
  - Verifies that the provided key is valid for the file using `Phantom.valid?/2`.
  - Deletes the file entry from the database.

  ## Returns

    - `{:ok, file}`: On successful deletion, returns the deleted file struct.
    - `{:error, "invalid key"}`: If the key is not authorized to delete the file.
    - `{:error, reason}`: If any operation (get, delete, etc.) fails.
  """
  @spec cypher_delete(user :: binary(), id :: integer(), key :: String.t()) :: response()
  def cypher_delete(user, id, key) do
    Repo.transaction(fn ->
      with {:ok, querry} <- CypherApi.get(id),
           {:ok, get_user} <- CypherApi.get_own(id),
           true <- get_user == user,
           true <- Phantom.valid?(querry, key),
           {:ok, _querry} <- CypherApi.delete(id),
           :ok <- Storage.del(user, id) do
        querry
      else
        false ->
          Repo.rollback("invalid key/user")

        {:error, reason} ->
          Repo.rollback(reason)
      end
    end)
  end

  @doc """
  Decrypts a single file or group entry by its ID.

  ## Parameters

    - `id` (string): The binary ID of the file or group to retrieve.
    - `key` (binary/string): The encryption key used to decrypt the item's name and (if applicable) its contents.
    - `opts` (keyword list, optional):
      - `:lazy` (boolean) — If `true`, skips file blob decryption and returns only metadata.
      - `:group` (boolean) — If `true`, retrieves a group instead of a file.

  ## Behavior

  - Fetches either a file (`Core.Cypher.Api.get/1`) or group (`GroupApi.get/1`) depending on the `:group` flag.
  - Decrypts the encrypted name using the provided key.
  - Returns the result depending on flags:
    - **File (lazy)**: Returns `id`, `name`, `ext`, and `group_id` only.
    - **File (full)**: Also includes decrypted `blob` content.
    - **Group**: Returns `id`, `name`, and `group_id`.

  ## Returns

    - `{:ok, map}`: A map containing the decrypted fields of the requested item.
    - `{:error, reason}`: If any decryption or retrieval fails.
  """
  @spec decrypt_one(user :: binary(), id :: integer(), key :: String.t(), opts :: Keyword.t()) :: {:ok, map()}
  def decrypt_one(user, id, key, opts \\ []) do
    lazy? = Keyword.get(opts, :lazy)
    group? = Keyword.get(opts, :group)

    {:ok, querry} =
      if group? do
        GroupApi.get(id)
      else
        CypherApi.get(id)
      end

    name = Encrypter.decrypt(querry.name, querry.name_iv, key)

    case {lazy?, group?} do
      {true, nil} ->
        {:ok,
         %{
           id: id,
           name: name,
           ext: querry.ext,
           group: querry.group_id
         }}

      {nil, nil} ->
        # Full file: download and decrypt using cache system
        {path, _created} = Cache.consume_cache(user, querry.id, querry.blob_iv, key)

        {:ok,
         %{
           id: id,
           name: name,
           path: path,
           ext: querry.ext,
           group: querry.group_id
         }}

      {_boolean, true} ->
        {:ok,
         %{
           id: id,
           name: name,
           group: querry.group_id
         }}
    end
  end

  @doc """
  Updates an encrypted file's name, content (blob), or group association.

  ## Parameters

    - `id` (string): The binary ID of the file to update.
    - `params` (map): One of the following:
      - `%{name: new_name, blob: new_blob}` — updates both the file name and content.
      - `%{name: new_name}` — updates only the file name.
      - `%{group_id: new_group}` — updates only the group association.
    - `key` (binary/string): The encryption key used to decrypt and validate the current file and re-encrypt updated data.

  ## Behavior

  Depending on the parameters:

  - If `name` and `blob` are given:
    - Encrypts the new name and blob.
    - Replaces the stored blob in the bucket.
    - Updates the file document in the database with new encryption fields and extension.

  - If only `name` is given:
    - Encrypts the new name.
    - Updates only the file name and extension.

  - If only `group_id` is given:
    - Validates the key and updates the group reference for the file.

  ## Returns

    - `{:ok, updated}`: On success, returns the updated file struct.
    - `{:error, "invalid key"}`: If the provided encryption key is not valid for this file.
  """
  @spec cypher_update(user :: binary(), id :: integer(), map(), key :: String.t()) :: response()
  def cypher_update(user, id, %{name: new_name, blob: new_blob}, key) do
    ext = Path.extname(new_name)
    new_name = Path.basename(new_name, ext)

    {name_iv, name} = Encrypter.encrypt(new_name, key)
    {blob_iv, blob} = Encrypter.encrypt(new_blob, key)

    {:ok, querry} = CypherApi.get(id)

    Repo.transaction(fn ->
      if Phantom.valid?(querry, key) do
        params = %{name_iv: name_iv, name: name, blob_iv: blob_iv, ext: ext}

        case Storage.put(user, id, blob) do
          :ok ->
            Cache.remove_cache(user, id)
            CypherApi.update(id, params)

          {:error, reason} ->
            Repo.rollback(reason)
        end
      else
        {:error, "invalid key/user"}
      end
    end)
  end

  def cypher_update(user, id, %{name: new_name}, key) do
    ext = Path.extname(new_name)
    new_name = Path.basename(new_name, ext)

    {name_iv, name} = Encrypter.encrypt(new_name, key)

    params = %{name_iv: name_iv, name: name, ext: ext}
    {:ok, querry} = CypherApi.get(id)

    with {:ok, owner} <- CypherApi.get_own(id),
         true <- owner == user,
         true <- Phantom.valid?(querry, key) do
      CypherApi.update(id, params)
    else
      false -> {:error, "invalid key/user"}
      error -> error
    end
  end

  def cypher_update(user, id, %{group_id: new_group}, key) do
    {:ok, querry} = CypherApi.get(id)

    with {:ok, owner} <- CypherApi.get_own(id),
         true <- owner == user,
         true <- Phantom.valid?(querry, key) do
      CypherApi.update(id, %{group_id: new_group})
    else
      false -> {:error, "invalid key/user"}
      error -> error
    end
  end

  @doc """
  Creates and inserts a new encrypted group into the system.

  ## Parameters

    - `group_name` (string): The plaintext name of the group to be created.
    - `key` (binary/string): The encryption key used to encrypt the group name and metadata.
    - `opts` (keyword list, optional):
      - `:group` (string) — Optional parent group ID to nest the new group under.

  ## Behavior

  - Validates the encryption key using `Phantom.insert_line?/1`.
  - Encrypts the group name.
  - Encrypts a generated message from `Phantom.get_text()`.
  - Stores the encrypted group in the database via `Core.Group.Api.insert/1`.

  ## Returns

    - `{:ok, id}`: The binary ID of the newly inserted group on success.
    - `nil`: If the key validation fails (`Phantom.insert_line?/1` returns `false`).
  """
  @spec group_insert(
          group_name :: String.t(),
          user :: binary,
          key :: String.t(),
          opts :: Keyword.t()
        ) ::
          response()
  def group_insert(group_name, user, key, opts \\ []) do
    group = Keyword.get(opts, :group)

    if Phantom.insert_line?(user, key) do
      {name_iv, name} = Encrypter.encrypt(group_name, key)
      {msg_iv, msg} = Phantom.get_text() |> Encrypter.encrypt(key)

      {:ok, querry} =
        GroupApi.insert(%{
          user_id: user,
          name_iv: name_iv,
          name: name,
          msg_iv: msg_iv,
          msg: msg,
          group_id: group
        })

      {:ok, querry.id}
    end
  end

  @doc """
  Updates an existing encrypted group's name or its parent group reference.

  ## Parameters

    - `id` (string): The binary ID of the group to update.
    - `params` (map): One of the following:
      - `%{name: new_name}` — updates the group's name.
      - `%{group_id: group_id}` — updates the parent group association.
    - `key` (binary/string): The encryption key used to validate and/or re-encrypt group data.

  ## Behavior

  - Retrieves the group by ID using `Core.Group.Api.get/1`.
  - Verifies the encryption key using `Phantom.valid?/2`.
  - If updating the name:
    - Encrypts the new name and updates the encrypted fields.
  - If updating the parent group:
    - Sets the `group_id` reference to the new parent.

  ## Returns

    - `{:ok, updated}`: On successful update.
    - `{:error, "invalid key"}`: If the encryption key is invalid for the group.
  """
  @spec group_update(user :: binary(), id :: integer(), map(), key :: String.t()) :: response()
  def group_update(user, id, %{name: new_name}, key) do
    {:ok, querry} = GroupApi.get(id)
    {name_iv, name} = Encrypter.encrypt(new_name, key)

    with {:ok, owner} <- GroupApi.get_own(id),
         true <- owner == user,
         true <- Phantom.valid?(querry, key) do
      GroupApi.update(id, %{name: name, name_iv: name_iv})
    else
      false -> {:error, "invalid key/user"}
      error -> error
    end
  end

  def group_update(user, id, %{group_id: group_id}, key) do
    {:ok, querry} = GroupApi.get(id)

    with {:ok, owner} <- GroupApi.get_own(id),
         true <- owner == user,
         true <- Phantom.valid?(querry, key) do
      GroupApi.update(id, %{group_id: group_id})
    else
      false -> {:error, "invalid key/user"}
      error -> error
    end
  end

  @doc """
  Deletes an encrypted group and all its contents recursively after validation.

  ## Parameters

    - `id` (string): The binary ID of the group to be deleted.
    - `key` (binary/string): The encryption key used to validate access to the group.

  ## Process

  The function:
    - Retrieves the group by ID using `Core.Group.Api.get/1`
    - Validates the encryption key using `Phantom.valid?/2`
    - Performs a cascading deletion of all nested contents through `delete_cascade/2`:
      - Recursively deletes all subgroups
      - Deletes all files within those groups
      - Cleans up binary storage for any deleted files

  ## Returns

    - `{:ok, group}`: Returns the deleted group struct on success.
    - `{:error, "invalid key"}`: If the provided encryption key is not valid.
    - `{:error, reason}`: If any step fails (retrieval, validation, or deletion).

  ## Security

  Requires a valid encryption key that matches the group's encryption scheme.
  The operation is irreversible and will permanently remove all nested content.
  """
  @spec group_delete(user :: binary(), id :: integer(), key :: String.t()) :: response()
  def group_delete(user, id, key) do
    with {:ok, querry} <- GroupApi.get(id),
         true <- Phantom.valid?(querry, key),
         {:ok, _boolean} <- delete_cascade(user, id, key) do
      ## Calls the private function `delete_cascade/2` to recursively delete all content within a group.

      {:ok, querry}
    else
      false -> {:error, "invalid key"}
      error -> error
    end
  end

  defp repeat_cascate(user, group_id, key) do
    {:ok, groups} = GroupApi.all_group(user, group_id)
    {:ok, datas} = CypherApi.all_group(user, group_id)

    contents = groups ++ datas

    if contents != [] do
      Enum.each(contents, fn item ->
        if Map.get(item, :ext) do
          cypher_delete(user, item.id, key)
        else
          repeat_cascate(user, item.id, key)
        end
      end)
    end

    GroupApi.delete(group_id)
  end

  defp delete_cascade(user, group_id, key) do
    with {:ok, querry} <- GroupApi.get(group_id),
         {:ok, get_user} <- GroupApi.get_own(group_id),
         true <- get_user == user,
         true <- Phantom.valid?(querry, key),
         {:ok, groups} <- GroupApi.all_group(user, group_id),
         {:ok, datas} <- CypherApi.all_group(user, group_id) do
      contents = groups ++ datas

      if contents == [] do
        GroupApi.delete(group_id)
        {:ok, false}
      else
        repeat_cascate(user, group_id, key)
        {:ok, true}
      end
    else
      false -> {:error, "invalid key/user"}
      error -> error
    end
  end

  @doc """
  Creates a duplicate of an encrypted file with optional modifications while maintaining security.

  ## Parameters

    - `id` (string): The binary ID of the original file to duplicate.
    - `params` (map): Modification parameters for the duplicate:
      - Can include any valid file fields (except protected metadata fields)
      - Typically used to change `group_id` for the new copy
    - `key` (binary/string): The encryption key used to:
      - Decrypt the original file's metadata
      - Re-encrypt the duplicate's data
      - Validate operation authorization

  ## Process

  The function:
    1. Retrieves the original file using `Core.Cypher.Api.get/1`
    2. Strips protected metadata fields (`__struct__`, `__meta__`, etc.)
    3. Merges the provided modification parameters
    4. Decrypts the original file name using `Encrypter.decrypt/2`
    5. Re-encrypts all sensitive data for the duplicate:
       - File name via `Encrypter.encrypt/2`
       - System message via `Phantom.get_text/0` + encryption
    6. Validates the encryption key with `Phantom.insert_line?/1`
    7. Inserts the new duplicate record via `Core.Cypher.Api.insert/1`

  ## Returns

    - `{:ok, new_id}`: The binary ID of the newly created duplicate file
    - `{:error, "invalid key"}`: If the encryption key fails validation
    - `{:error, reason}`: If any decryption, encryption or database operation fails

  ## Security Notes

  - Maintains all encryption standards of the original file
  - Generates fresh IVs for all encrypted fields
  - Preserves no direct references to the original's encrypted data
  - Requires valid encryption key for both read and write operations
  """
  @spec cypher_duplicate(user :: binary(), id :: integer(), params :: map(), key :: String.t()) ::
          response()
  def cypher_duplicate(user, id, params, key) do
    {:ok, querry} = CypherApi.get(id)

    original =
      Map.drop(querry, [
        :__struct__,
        :__meta__,
        :id,
        :group,
        :user,
        :inserted_at,
        :updated_at
      ])

    duplicate = Map.merge(original, params)

    ## This process is necessary about the unique name constraint.
    dec_name =
      Encrypter.decrypt(
        duplicate.name,
        duplicate.name_iv,
        key
      )

    {name_iv, name} =
      Encrypter.encrypt(
        dec_name,
        key
      )

    {msg_iv, msg} =
      Phantom.get_text()
      |> Encrypter.encrypt(key)

    duplicate =
      Map.merge(
        duplicate,
        %{name_iv: name_iv, name: name, msg_iv: msg_iv, msg: msg}
      )

    Repo.transaction(fn ->
      case Storage.get_stream(user, querry.id) do
        {:ok, stream} ->
          with true <- Phantom.insert_line?(user, key),
               {:ok, querry} <- CypherApi.insert(duplicate),
               :ok <- Storage.put_stream(user, querry.id, stream) do
            querry.id
          else
            false -> {:error, "invalid key"}
            error -> error
          end

        {:error, reason} ->
          Repo.rollback(reason)
      end
    end)
  end

  @doc """
  Creates a complete duplicate of an encrypted group including all nested contents.

  ## Parameters

    - `id` (string): The binary ID of the original group to duplicate
    - `params` (map): Modification parameters for the new group (typically `group_id`)
    - `key` (binary/string): Encryption key for decrypting/encrypting contents

  ## Process

  1. Retrieves and decrypts original group metadata
  2. Creates new encrypted group with fresh IVs
  3. Recursively duplicates all nested groups and files using:
     - `Utils.get_tree/2` to fetch hierarchy
     - `Utils.mount_tree/4` to rebuild structure
  4. Maintains original encryption standards for all copies

  ## Returns

    - `{:ok, new_id}`: ID of the new group root
    - `{:error, "invalid key"}`: If key validation fails
  """
  @spec group_duplicate(user :: binary(), id :: integer(), params :: map(), key :: String.t()) ::
          response()
  def group_duplicate(user, id, params, key) do
    {:ok, querry} = GroupApi.get(id)

    original =
      Map.drop(querry, [
        :__struct__,
        :__meta,
        :id,
        :group,
        :cypher,
        :user,
        :subgroup,
        :inserted_at,
        :updated_at
      ])

    duplicate = Map.merge(original, params)

    dec_name =
      Encrypter.decrypt(
        duplicate.name,
        duplicate.name_iv,
        key
      )

    {name_iv, name} =
      Encrypter.encrypt(
        dec_name,
        key
      )

    {msg_iv, msg} =
      Phantom.get_text()
      |> Encrypter.encrypt(key)

    duplicate =
      Map.merge(
        duplicate,
        %{name_iv: name_iv, name: name, msg_iv: msg_iv, msg: msg}
      )

    with true <- Phantom.insert_line?(user, key),
         {:ok, owner} <- GroupApi.get_own(id),
         true <- owner == user do
      {:ok, dup_querry} = GroupApi.insert(duplicate)

      duplicate_content = fn
        content, :data ->
          {:ok, new_cypher} = CypherApi.insert(content)
          # Copy the encrypted blob from the original file to the new file
          {:ok, stream} = Storage.get_stream(user, content.original_id)
          Storage.put(user, new_cypher.id, stream)
          new_cypher

        content, :group ->
          {:ok, subquerry} = GroupApi.insert(content)
          # Preserve all params and update group_id for child items
          Map.put(content, :group_id, subquerry.id)
      end

      Utils.get_tree(user, querry.id, key, lazy: true)
      |> Utils.mount_tree(
        %{group_id: dup_querry.id, user_id: user},
        duplicate_content,
        key
      )

      {:ok, dup_querry.id}
    else
      false -> {:error, "invalid key/user"}
      error -> error
    end
  end

  @doc """
  Generates a ZIP archive of either a single file or an entire group structure.

  ## Parameters

    - `id` (string | "main"): ID of item to zip ("main" for root group)
    - `key` (binary/string): Decryption key for contents
    - `opts` (keyword list):
      - `:group` (boolean): Set true when zipping a group

  ## Behavior

  For groups:
    - Decrypts group name
    - Fetches complete tree structure (Using Utils.get_tree/2)
    - Creates ZIP with preserved hierarchy

  For files:
    - Decrypts both filename and content
    - Packages as single file in ZIP

  ## Returns

    - ZIP binary data on success
    - Original error tuples on failure
  """
  @spec zip_content(user :: binary(), id :: integer(), key :: String.t(), opts :: Keyword.t()) ::
          {:ok, Path.t()} | {:error, String.t()}
  def zip_content(user, id, key, opts \\ []) do
    group? = Keyword.get(opts, :group)

    ## Since `nil` can’t be passed as a valid value in a .heex (only strings), this conversion is necessary.
    id =
      if id == "main" do
        nil
      else
        id
      end

    if group? do
      {:ok, name} =
        if id do
          {:ok, querry} = GroupApi.get(id)

          {:ok,
            Encrypter.decrypt(
              querry.name,
              querry.name_iv,
              key
            )
          }
        else
          {:ok, "Main"}
        end

      tree = Utils.get_tree(user, id, key)
      Utils.zip_folder(tree, name)
    else
      case CypherApi.get(id) do
        {:ok, querry} ->
          name =
            Encrypter.decrypt(
              querry.name,
              querry.name_iv,
              key
            )

          blob = Cache.get_content(user, querry.id, querry.blob_iv, key)

          {:ok,
            Utils.zip_file(
              name <> querry.ext,
              blob
            )
          }

        error ->
          error
      end
    end
  end

  @doc """
  Deletes ALL encrypted groups and files from the system.

  ## Parameters
    - `key` (binary/string): Admin-level encryption key for validation

  ## Process
  1. Validates the key via `Phantom.insert_line?/1`
  2. Performs complete wipe of:
     - All groups via `Core.Group.Api.delete_all()`
     - All files via `Core.Cypher.Api.delete_all()`

  ## Returns
    - `{:ok, count}`: Total number of deleted records (groups + files)
    - `{:error, reason}`: If key validation fails or deletion encounters errors

  ## Security Warning
  - This is a DESTRUCTIVE operation with no recovery
  - Requires valid database key
  - Should be restricted to maintenance/emergency use
  """
  @spec delete_all(user :: binary(), key :: String.t()) ::
          {:ok, non_neg_integer()} | {:error, String.t()}
  def delete_all(user, key) do
    with true <- Phantom.insert_line?(user, key),
         {count_group, nil} <- GroupApi.delete_all(user),
         {count_data, nil} <- CypherApi.delete_all(user),
         :ok <- Storage.del_all(user) do
      {:ok, count_group + count_data}
    else
      error -> error
    end
  end

  @spec unzip_content(path :: Path.t(), user :: binary(), key :: binary(), opts :: Keyword.t()) ::
          pos_integer()
  def unzip_content(path, user, key, opts \\ []) do
    group =
      Keyword.get(opts, :group)
      |> Validate.int!()

    zip_path = Variables.tmp_dir() <> "zips/"

    if Phantom.insert_line?(user, key) do
      {:ok, path_charlist} =
        :zip.extract(
          path |> String.to_charlist(),
          cwd: zip_path |> String.to_charlist()
        )

      path_string =
        Enum.map(path_charlist, fn item ->
          List.to_string(item)
        end)

      {:ok, agent} = Agent.start_link(fn -> %{} end)

      count =
        for item <- path_string do
          Utils.create_folder(user, item, key, agent: agent, group: group)
        end |> Enum.count()

      exclude_path =
        Path.relative_to(
          List.first(path_string),
          zip_path
        )
        |> Path.split()
        |> List.first()

      File.rm_rf!(zip_path <> exclude_path)
      count
    else
      {:error, "invalid key"}
    end
  end

  @spec user_insert(name :: String.t(), email :: String.t(), password :: String.t()) ::
          {:error, String.t()} | {:ok, pos_integer()}
  def user_insert(name, email, password) do
    case UserApi.get_email(email) do
      {:ok, _querry} ->
        {:error, "email alredy been taken"}

      {:error, _reason} ->
        salt = Encrypter.random()
        passhash = salt <> Encrypter.hash(password)

        {:ok, querry} =
          UserApi.insert(%{
            name: name,
            email: email,
            passhash: passhash
          })

        {:ok, querry.id}
    end
  end

  @spec user_validate(email :: String.t(), password :: String.t()) ::
          {:ok, non_neg_integer()} | {:error, String.t()}
  def user_validate(email, password) do
    case UserApi.get_email(email) do
      {:ok, querry} ->
        <<_salt::binary-size(16), passhash::binary>> = querry.passhash

        if Encrypter.hash(password) == passhash do
          {:ok, querry.id}
        else
          {:error, "invalid email/passwd"}
        end

      error ->
        error
    end
  end

  @doc """
  Deletes a user and all their associated data from the system.

  This function performs a complete cleanup by:
  1. Deleting all user's groups from the database
  2. Deleting all user's files from the database  
  3. Deleting all user's files from storage (using batch processing)
  4. Finally deleting the user account

  ## Parameters
  - `id` - The binary ID of the user to delete

  ## Returns
  - `:ok` - If the user and all data were successfully deleted
  - `:error` - If any step of the deletion process failed

  ## Notes
  - This operation is irreversible
  - Uses batch processing for storage deletion to handle large numbers of files
  - Continues with user deletion even if some data cleanup fails
  - Provides detailed logging for each step of the deletion process
  """
  @spec user_delete(user :: binary()) :: :ok | :error
  def user_delete(user) do
    require Logger

    Logger.info("Starting user deletion process for user #{user}")

    # Delete all user's groups from database
    case GroupApi.delete_all(user) do
      {count_groups, nil} ->
        Logger.info("Deleted #{count_groups} groups for user #{user}")

      {count_groups, _error} ->
        Logger.warning("Deleted #{count_groups} groups for user #{user}, some deletions failed")

      error ->
        Logger.error("Failed to delete groups for user #{user}: #{inspect(error)}")
    end

    # Delete all user's files from database
    case CypherApi.delete_all(user) do
      {count_files, nil} ->
        Logger.info("Deleted #{count_files} files from database for user #{user}")

      {count_files, _error} ->
        Logger.warning(
          "Deleted #{count_files} files from database for user #{user}, some deletions failed"
        )

      error ->
        Logger.error("Failed to delete files from database for user #{user}: #{inspect(error)}")
    end

    # Delete all user's files from storage using batch processing
    case Storage.del_all(user) do
      :ok ->
        Logger.info("Deleted many files from storage for user #{user}")

      {:error, reason} ->
        Logger.error("Failed to delete files from storage for user #{user}: #{reason}")
    end

    # Finally delete the user account
    case UserApi.delete(user) do
      {:ok, _querry} ->
        Logger.info("Successfully deleted user #{user} and all associated data")
        :ok

      error ->
        Logger.error("Failed to delete user account #{user}: #{inspect(error)}")
        :error
    end
  end

  def user_get(user, opts \\ []) do
    email = Keyword.get(opts, :email)

    if email do
      UserApi.get_email(email)
    else
      UserApi.get(user)
    end
  end

  def user_update(email, %{password: password}) do
    case UserApi.get_email(email) do
      {:ok, %{id: user}} ->
        salt = Encrypter.random()
        passhash = salt <> Encrypter.hash(password)

        UserApi.update(user, %{passhash: passhash})

      error ->
        error
    end
  end
end
