defmodule MaxGallery.Context do
    alias MaxGallery.Core.Data.Api, as: DataApi
    alias MaxGallery.Core.Group.Api, as: GroupApi
    alias MaxGallery.Core.Data
    alias MaxGallery.Core.Group
    alias MaxGallery.Core.Bucket
    alias MaxGallery.Encrypter
    alias MaxGallery.Phantom
    alias MaxGallery.Utils
    @type querry :: [%Data{} | %Group{} | map()] 
    

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

      - `MaxGallery.Core.Data.Api` for file entries;
      - `MaxGallery.Core.Group.Api` for group entities;
      - `MaxGallery.Encrypter` for encryption/decryption;
      - `MaxGallery.Bucket` for encrypted binary storage;
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
    @spec cypher_insert(path :: Path.t(), key :: String.t(), opts :: Keyword.t()) :: {:ok, querry()} | {:error, String.t()}
    def cypher_insert(path, key, opts \\ []) do
        name = Keyword.get(opts, :name) 
        group = Keyword.get(opts, :group)

        ext = 
            if name do
                Path.extname(name)
            else
                Path.extname(path)
            end 

        {:ok, {name_iv, name}} = 
            if name do
                Path.basename(name, ext)
                |> Encrypter.encrypt(key)
            else
                Path.basename(path, ext)
                |> Encrypter.encrypt(key)
            end 


        ## The `cyphers` table stores the file’s metadata and the identifier to find the content inside the `gridfs` bucket.
        with true <- Phantom.insert_line?(key),
             {:ok, {blob_iv, blob}} <- Encrypter.file(:encrypt, path, key),
             {:ok, file_id} <- Bucket.write(blob) |> Bucket.upload(name),
             {:ok, {msg_iv, msg}} <- Encrypter.encrypt(Phantom.get_text(), key),
             {:ok, querry} <- DataApi.insert(%{
                 file_id: file_id,
                 name_iv: name_iv,
                 name: name,
                 blob_iv: blob_iv,
                 ext: ext,
                 msg: msg,
                 msg_iv: msg_iv,
                 group_id: group}) do

            {:ok, querry.id}
        else
            false -> {:error, ""}
            error -> error
        end
    end


    ## Private recursive function to return the already encrypted data of each date/group to be stored in the database.
    defp send_package(%{ext: _ext} = item, lazy?, key) do
        {:ok, name} = {item.name_iv, item.name} |> Encrypter.decrypt(key)

        if lazy? do
            %{name: name, ext: item.ext, id: item.id, group: item.group_id}
        else
            {:ok, enc_blob} = Bucket.download(item.file_id)

            {:ok, blob} = {item.blob_iv, enc_blob} |> Encrypter.decrypt(key)
            %{name: name, blob: blob, ext: item.ext, id: item.id, group: item.group_id}
        end
    end
    defp send_package(item, _lazy, key) do
        {:ok, name} = {item.name_iv, item.name} |> Encrypter.decrypt(key)
        %{name: name, id: item.id, group: item.group_id} 
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
    @spec decrypt_all(key :: String.t(), opts :: Keyword.t()) :: {:ok, querry()} 
    def decrypt_all(key, opts \\ []) do
        lazy? = Keyword.get(opts, :lazy)
        only = Keyword.get(opts, :only)
        group_id = Keyword.get(opts, :group)

        {:ok, contents} = Utils.get_group(group_id, only: only)

        querry = 
            for item <- contents do
                send_package(item, lazy?, key)
            end |> Phantom.encode_bin()

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

    - Retrieves the file by its ID using `Core.Data.Api.get/1`.
    - Verifies that the provided key is valid for the file using `Phantom.valid?/2`.
    - Deletes the file entry from the database.
    - If `:shallow` is not set or is false, also removes the file's encrypted binary blob from storage via `Core.Bucket.delete/1`.

    ## Returns

      - `{:ok, file}`: On successful deletion, returns the deleted file struct.
      - `{:error, "invalid key"}`: If the key is not authorized to delete the file.
      - `{:error, reason}`: If any operation (get, delete, etc.) fails.
    """
    @spec cypher_delete(id :: binary(), key :: String.t(), opts :: Keyword.t()) :: {:ok, querry()} | {:error, String.t()}
    def cypher_delete(id, key, opts \\ []) do
        shallow? = Keyword.get(opts, :shallow) 

        with {:ok, querry} <- DataApi.get(id),
             true <- Phantom.valid?(querry, key),
             {:ok, _querry} <- DataApi.delete(id) do

            ## Option to not delete the actual content in the bucket, only its metadata. (Not recoverable).
            if !shallow? do
                Bucket.delete(querry.file_id)
            end

            {:ok, querry}
        else
            false -> {:error, "invalid key"}
            error -> error
        end
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

    - Fetches either a file (`Core.Data.Api.get/1`) or group (`GroupApi.get/1`) depending on the `:group` flag.
    - Decrypts the encrypted name using the provided key.
    - Returns the result depending on flags:
      - **File (lazy)**: Returns `id`, `name`, `ext`, and `group_id` only.
      - **File (full)**: Also includes decrypted `blob` content.
      - **Group**: Returns `id`, `name`, and `group_id`.

    ## Returns

      - `{:ok, map}`: A map containing the decrypted fields of the requested item.
      - `{:error, reason}`: If any decryption or retrieval fails.
    """
    @spec decrypt_one(id :: binary(), key :: String.t(), opts :: Keyword.t()) :: {:ok, querry()} | {:error, String.t()}
    def decrypt_one(id, key, opts \\ []) do
        lazy? = Keyword.get(opts, :lazy)
        group? = Keyword.get(opts, :group)

        {:ok, querry} = 
            if group? do
                GroupApi.get(id)
            else
                DataApi.get(id)
            end


        with {:ok, name} <- Encrypter.decrypt({querry.name_iv, querry.name}, key) do

            case {lazy?, group?} do
                {true, nil} ->
                    {:ok, %{
                        id: id,
                        name: name,
                        ext: querry.ext,
                        group: querry.group_id
                    }}
                
                {nil, nil} ->
                    {:ok, enc_blob} = Bucket.download(querry.file_id)
                    {:ok, blob} = Encrypter.decrypt({querry.blob_iv, enc_blob}, key)

                    {:ok, %{
                        id: id,
                        name: name,
                        blob: blob,
                        ext: querry.ext,
                        group: querry.group_id
                    }}

                {_boolean, true} ->
                    {:ok, %{
                        id: id,
                        name: name,
                        group: querry.group_id
                    }}
            end
        else
            error -> error
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
    @spec cypher_update(id :: binary(), map(), key :: String.t()) :: {:ok, querry()} | {:error, String.t()}
    def cypher_update(id, %{name: new_name, blob: new_blob}, key) do
        ext = Path.extname(new_name)
        new_name = Path.basename(new_name, ext)

        {:ok, {name_iv, name}} = Encrypter.encrypt(new_name, key)
        {:ok, {blob_iv, blob}} = Encrypter.encrypt(new_blob, key)

        {:ok, querry} = DataApi.get(id)

        if Phantom.valid?(querry, key) do
            {:ok, file_id} = Bucket.replace(querry.file_id, blob)
            params = %{file_id: file_id, name_iv: name_iv, name: name, blob_iv: blob_iv, ext: ext}

            DataApi.update(id, params)
        else
            {:error, "invalid key"}
        end
    end
    def cypher_update(id, %{name: new_name}, key) do
        ext = Path.extname(new_name)
        new_name = Path.basename(new_name, ext)

        {:ok, {name_iv, name}} = Encrypter.encrypt(new_name, key)

        params = %{name_iv: name_iv, name: name, ext: ext}
        {:ok, querry} = DataApi.get(id)

        if Phantom.valid?(querry, key) do
            DataApi.update(id, params)
        else
            {:error, "invalid key"}
        end
    end
    def cypher_update(id, %{group_id: new_group}, key) do
        {:ok, querry} = DataApi.get(id)

        if Phantom.valid?(querry, key) do
            DataApi.update(id, %{group_id: new_group})
        else
            {:error, "invalid key"}
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
    @spec group_insert(group_name :: String.t(), key :: String.t(), opts :: Keyword.t()) :: {:ok, querry()} | {:error, String.t()}
    def group_insert(group_name, key, opts \\ []) do
        group = Keyword.get(opts, :group)

        if Phantom.insert_line?(key) do
            {:ok, {name_iv, name}} = Encrypter.encrypt(group_name, key)
            {:ok, {msg_iv, msg}} = Phantom.get_text() |> Encrypter.encrypt(key)

            {:ok, querry} = GroupApi.insert(%{name_iv: name_iv, name: name, msg_iv: msg_iv, msg: msg, group_id: group})
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
    @spec group_update(id :: binary(), map(), key :: String.t()) :: {:ok, querry()} | {:error, String.t()}
    def group_update(id, %{name: new_name}, key) do 
        {:ok, querry} = GroupApi.get(id)
        {:ok, {name_iv, name}} = Encrypter.encrypt(new_name, key)

        if Phantom.valid?(querry, key) do
            GroupApi.update(id, %{name: name, name_iv: name_iv})
        else
            {:error, "invalid key"}
        end
    end
    def group_update(id, %{group_id: group_id}, key) do
        {:ok, querry} = GroupApi.get(id)

        if Phantom.valid?(querry, key) do
            GroupApi.update(id, %{group_id: group_id})
        else
            {:error, "invalid key"}
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
    @spec group_delete(id :: binary(), key :: String.t()) :: {:ok, querry()} | {:error, String.t()}
    def group_delete(id, key) do
        with {:ok, querry} <- GroupApi.get(id),
             true <- Phantom.valid?(querry, key),
             {:ok, _boolean} <- delete_cascade(id, key) do 
             ## Calls the private function `delete_cascade/2` to recursively delete all content within a group.

            {:ok, querry}
        else
            false -> {:error, "invalid key"}
            error -> error
        end 
    end


    defp repeat_cascate(group_id, key) do
        {:ok, groups} = GroupApi.all_group(group_id)
        {:ok, datas} = DataApi.all_group(group_id)

        contents = groups ++ datas
        if contents != [] do
            Enum.each(contents, fn item -> 

                if Map.get(item, :ext) do
                    cypher_delete(item.id, key)
                else
                    repeat_cascate(item.id, key)
                end

            end)
        end

        GroupApi.delete(group_id)
    end
    defp delete_cascade(group_id, key) do
        with {:ok, querry} <- GroupApi.get(group_id),
             true <- Phantom.valid?(querry, key),
             {:ok, groups} <- GroupApi.all_group(group_id),
             {:ok, datas} <- DataApi.all_group(group_id) do

            contents = groups ++ datas
            if contents == [] do
                GroupApi.delete(group_id)
                {:ok, false}
            else
                repeat_cascate(group_id, key)
                {:ok, true}
            end

        else
            false -> {:error, "invalid key"}
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
      1. Retrieves the original file using `Core.Data.Api.get/1`
      2. Strips protected metadata fields (`__struct__`, `__meta__`, etc.)
      3. Merges the provided modification parameters
      4. Decrypts the original file name using `Encrypter.decrypt/2`
      5. Re-encrypts all sensitive data for the duplicate:
         - File name via `Encrypter.encrypt/2`
         - System message via `Phantom.get_text/0` + encryption
      6. Validates the encryption key with `Phantom.insert_line?/1`
      7. Inserts the new duplicate record via `Core.Data.Api.insert/1`

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
    @spec cypher_duplicate(id :: binary(), params :: map(), key :: String.t()) :: {:ok, querry()} | {:error, String.t()}
    def cypher_duplicate(id, params, key) do
        {:ok, querry} = DataApi.get(id)

        original = Map.drop(querry, [
            :__struct__,
            :__meta__,
            :id,
            :group,
            :inserted_at,
            :updated_at
        ])
        duplicate = Map.merge(original, params)
        
        {:ok, dec_name} = Encrypter.decrypt(
            {duplicate.name_iv, duplicate.name},
            key
        ) 

        {:ok, {name_iv, name}} = Encrypter.encrypt(
            dec_name,
            key
        )

        {:ok, {msg_iv, msg}} = Phantom.get_text()
                        |> Encrypter.encrypt(key)

        duplicate = Map.merge(duplicate,
            %{name_iv: name_iv, name: name, msg_iv: msg_iv, msg: msg}
        )

        with true <- Phantom.insert_line?(key),
             {:ok, querry} <- DataApi.insert(duplicate) do

            {:ok, querry.id}
        else
            false -> {:error, "invalid key"}
            error -> error
        end
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
    @spec group_duplicate(id :: binary(), params :: map(), key :: String.t()) :: {:ok, querry()} | {:error, String.t()}
    def group_duplicate(id, params, key) do
        {:ok, querry} = GroupApi.get(id)

        original = Map.drop(querry, [
            :__struct__,
            :__meta,
            :id,
            :group,
            :cypher,
            :subgroup,
            :inserted_at,
            :updated_at
        ])

        duplicate = Map.merge(original, params)
        
        {:ok, dec_name} = Encrypter.decrypt(
            {duplicate.name_iv, duplicate.name},
            key
        ) 

        {:ok, {name_iv, name}} = Encrypter.encrypt(
            dec_name,
            key
        )

        {:ok, {msg_iv, msg}} = Phantom.get_text()
                        |> Encrypter.encrypt(key)

        duplicate = Map.merge(duplicate,
            %{name_iv: name_iv, name: name, msg_iv: msg_iv, msg: msg}
        )

        if Phantom.insert_line?(key) do
            {:ok, dup_querry} = GroupApi.insert(duplicate)

            duplicate_content = fn
                (content, :data) ->
                    {:ok, file_id} = Bucket.write(content.blob) 
                              |> Bucket.upload(content.name)

                    %{content | file_id: file_id}
                    |> DataApi.insert()


                (content, :group) ->
                    {:ok, subquerry} = GroupApi.insert(content)
                    %{group_id: subquerry.id}
            end


            Utils.get_tree(querry.id, key)
            |> Utils.mount_tree(
                %{group_id: dup_querry.id}, 
                duplicate_content, 
                key
            )

            {:ok, dup_querry.id}
        else
            {:error, "invalid key"}
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
    @spec zip_content(id :: binary(), key :: String.t(), opts :: Keyword.t()) :: {:ok, Path.t()} | {:error, String.t()}
    def zip_content(id, key, opts \\ []) do
        group? = Keyword.get(opts, :group)
        id = 
            ## Since `nil` can’t be passed as a valid value in a .heex (only strings), this conversion is necessary.
            if id == "main" do
                nil
            else
                id
            end


        if group? do
            {:ok, name} = 
                if id do
                    {:ok, querry} = GroupApi.get(id)
                    Encrypter.decrypt(
                        {querry.name_iv, querry.name},
                        key
                    )
                else
                    {:ok, "Main"}
                end

            tree = Utils.get_tree(id, key)
            Utils.zip_folder(tree, name)
        else

            case DataApi.get(id) do
                {:ok, querry} ->
                    {:ok, name} = Encrypter.decrypt(
                        {querry.name_iv, querry.name},
                        key
                    )

                    {:ok, enc_blob} = Bucket.download(querry.file_id)
                    {:ok, blob} = Encrypter.decrypt(
                        {querry.blob_iv, enc_blob},
                        key
                    )

                    Utils.zip_file(
                        name <> querry.ext,
                        blob
                    )


                error -> error
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
       - All files via `Core.Data.Api.delete_all()`
       - All storage content via `Core.Bucket.drop()` 

    ## Returns
      - `{:ok, count}`: Total number of deleted records (groups + files)
      - `{:error, reason}`: If key validation fails or deletion encounters errors

    ## Security Warning
    - This is a DESTRUCTIVE operation with no recovery
    - Requires valid database key
    - Should be restricted to maintenance/emergency use
    """
    @spec delete_all(key :: String.t()) :: {:ok, non_neg_integer()} | {:error, String.t()}
    def delete_all(key) do
        with true <- Phantom.insert_line?(key),
             {count_group, nil} <- GroupApi.delete_all(),
             {count_data, nil} <- DataApi.delete_all(),
             :ok <- Bucket.drop() do

            {:ok, count_group + count_data}
        else
            error -> error
        end
    end


    @doc """
    Performs a system-wide encryption key rotation for all groups and files.

    ## Parameters
      - `key` (binary/string): Current valid admin encryption key
      - `new_key` (binary/string): New encryption key to apply system-wide

    ## Process
    1. Validates current admin key via `Phantom.insert_line?/1`
    2. For all groups:
       - Decrypts names with old key
       - Re-encrypts names and metadata with new key
    3. For all files:
       - Decrypts names and content with old key
       - Re-encrypts with new key
       - Updates storage with new encrypted blobs
    4. Maintains all data relationships and structure

    ## Returns
      - `{:ok, count}`: Total number of updated records
      - `{:error, "invalid key"}`: If current key validation fails

    ## Security Notes
    - Requires uninterrupted execution (consider transaction wrapping)
    - Old key must remain valid during migration
    - Generates fresh IVs for all encrypted fields
    - Does NOT maintain ability to decrypt with old key
    """
    @spec update_all(key :: String.t(), new_key :: String.t()) :: {:ok, non_neg_integer()} | {:error, String.t()}
    def update_all(key, new_key) do
        ## This function is poor, if the user cancel the operation in the process, the entire database will be corrupted. Should i refactor that?
        if Phantom.insert_line?(key) do
            {:ok, group_list} = GroupApi.all()
            Enum.each(group_list, fn group ->
                {:ok, old_name} = Encrypter.decrypt(
                    {group.name_iv, group.name},
                    key
                )
                {:ok, {name_iv, name}} = Encrypter.encrypt(
                    old_name,
                    new_key
                )

                {:ok, {msg_iv, msg}} = Encrypter.encrypt(
                    Phantom.get_text(),
                    new_key
                )

                GroupApi.update(
                    group.id, 
                    %{name_iv: name_iv, name: name, msg_iv: msg_iv, msg: msg}
                )
            end)

            
            {:ok, data_list} = DataApi.all()
            Enum.each(data_list, fn data ->
                {:ok, old_name} = Encrypter.decrypt(
                    {data.name_iv, data.name},
                    key
                )
                {:ok, {name_iv, name}} = Encrypter.encrypt(
                    old_name,
                    new_key
                )

                {:ok, enc_blob} = Bucket.download(data.file_id)
                {:ok, old_blob} = Encrypter.decrypt(
                    {data.blob_iv, enc_blob},
                    key
                )
                {:ok, {blob_iv, blob}} = Encrypter.encrypt(
                    old_blob,
                    new_key
                )

                {:ok, {msg_iv, msg}} = Encrypter.encrypt(
                    Phantom.get_text(),
                    new_key
                )

                {:ok, file_id} = Bucket.replace(data.file_id, blob)
                DataApi.update(
                    data.id, 
                    %{file_id: file_id, name_iv: name_iv, name: name, blob_iv: blob_iv, msg_iv: msg_iv, msg: msg}
                )
            end)

            count = Enum.count(group_list) + Enum.count(data_list) 
            {:ok, count}
        else
            {:error, "invalid key"}
        end
    end

end
