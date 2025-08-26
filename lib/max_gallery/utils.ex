defmodule MaxGallery.Utils do
  alias MaxGallery.Core.Cypher.Api, as: CypherApi
  alias MaxGallery.Core.Group.Api, as: GroupApi
  alias MaxGallery.Encrypter
  alias MaxGallery.Phantom
  alias MaxGallery.Cache
  alias MaxGallery.Variables
  alias MaxGallery.Validate
  @type tree :: [map()]
  @zip_path Variables.tmp_dir() <> "zips"

  @moduledoc """
  This module provides utility functions for supporting operations across the MaxGallery system.

  It offers essential helper functions for:

  - Navigating and manipulating group hierarchies and file structures;
  - Calculating aggregated sizes of groups and files;
  - Handling timestamps with timezone adjustments;
  - Building and processing encrypted directory trees;
  - Generating zip archives from files or entire folder structures;
  - Performing pattern matching searches on encrypted content.

  Key utilities include:

  - `get_tree/3` - Recursively builds decrypted directory structures;
  - `mount_tree/4` - Reconstructs encrypted trees for storage;
  - `zip_file/2` and `zip_folder/2` - Creates zip archives from content;
  - `get_size/2` - Calculates total size of items/groups;
  - `get_timestamps/2` - Handles localized timestamp operations.

  The module works closely with:

  - `MaxGallery.Encrypter` for cryptographic operations;
  - `MaxGallery.Core` APIs for data access;
  - `MaxGallery.Phantom` for metadata generation.

  All cryptographic operations require proper encryption keys, and file operations
  are performed in a temporary directory that should be cleaned up after use.
  """

  @doc """
  Retrieves the parent group ID for a given item ID.

  ## Parameters
  - `id` - The ID of the item (group or file) to look up. Can be `nil`.

  ## Returns
  - `nil` if the input ID is `nil`
  - The parent group ID (`group_id`) if the item exists

  ## Notes
  - Operates exclusively through the GroupApi module
  - Will raise an exception if the queried item lacks a group_id field
  - Does not validate the existence of the returned parent group
  - Primarily used for navigation within group hierarchies
  """
  @spec get_back(id :: binary()) :: binary()
  def get_back(id) do
    case id do
      nil ->
        nil

      _id ->
        {:ok, querry} = GroupApi.get(id)
        Map.fetch!(querry, :group_id)
    end
  end

  @doc """
  Retrieves all items (files and groups) belonging to a specified group.

  ## Parameters
  - `id` - The ID of the parent group
  - `opts` - Optional keyword list for filtering:
    - `:only` - Atom specifying what to return:
      - `:datas` - Returns only files
      - `:groups` - Returns only subgroups
      - `nil` (default) - Returns both files and subgroups

  ## Returns
  - `{:ok, list}` - Tuple with :ok and a list of items on success
    - The list contains both file and group structs when no filter is applied
    - Contains only the requested type when filtered

  ## Notes
  - Makes parallel calls to CypherApi (for files) and GroupApi (for subgroups)
  - The combined result maintains no particular order
  - Returns empty list if the group contains no items
  - Does not recursively fetch items from nested subgroups
  """
  @spec get_group(id :: binary(), opts :: Keyword.t()) :: {:ok, MaxGallery.Context.querry()}
  def get_group(id, opts \\ []) do
    only = Keyword.get(opts, :only)

    case only do
      nil ->
        {:ok, datas} = CypherApi.all_group(id)
        {:ok, groups} = GroupApi.all_group(id)

        {:ok, groups ++ datas}

      :datas ->
        CypherApi.all_group(id)

      :groups ->
        GroupApi.all_group(id)
    end
  end

  @doc """
  Calculates the total size of a file or recursively for a group and its contents.

  ## Parameters
  - `id` - The ID of the item (file or group) to measure
  - `opts` - Optional keyword list:
    - `:group` - Boolean flag indicating whether the ID refers to a group
      - When true, calculates recursively for all contents
      - When false or omitted for files, returns individual file size

  ## Returns
  - Integer representing the total size in bytes:
    - For files: The actual file size from storage
    - For groups: Sum of all contained items' sizes
    - 0 for empty groups

  ## Notes
  - For groups, performs recursive calculation through all nested contents
  - Determines if items are subgroups by checking for :ext field presence
  - Returns raw size values without unit conversion
  - May raise exceptions if the item doesn't exist or lacks required fields
  """
  @spec get_size(id :: binary(), opts :: Keyword.t()) :: non_neg_integer()
  def get_size(id, opts \\ []) do
    group? = Keyword.get(opts, :group)

    if group? do
      {:ok, contents} = get_group(id)

      if contents == [] do
        0
      else
        Enum.map(contents, fn item ->
          subgroup? =
            if Map.get(item, :ext) do
              nil
            else
              true
            end

          get_size(item.id, group: subgroup?)
        end)
        |> Enum.sum()
      end
    else
      {:ok, length} = CypherApi.get_length(id)
      length
    end
  end

  @doc """
  Retrieves and adjusts timestamps for an item (file or group) to local time.

  ## Parameters
  - `id` - The ID of the item to get timestamps for
  - `opts` - Optional keyword list:
    - `:group` - Boolean flag indicating whether the ID refers to a group
      - When true, uses GroupApi
      - When false or omitted, uses CypherApi

  ## Returns
  - Map with adjusted timestamps:
    - `:inserted_at` - Local time when the item was created
    - `:updated_at` - Local time when the item was last modified

  ## Notes
  - Automatically converts UTC timestamps to local time
  - Calculates timezone offset based on system time
  - Only adjusts the hour component (doesn't handle minutes)
  - Preserves the original timestamp structure from the database
  - Will raise if the item doesn't exist or lacks timestamp fields
  """
  @spec get_timestamps(id :: binary(), Keyword.t()) :: map()
  def get_timestamps(id, opts \\ []) do
    group? = Keyword.get(opts, :group)

    {:ok, timestamps} =
      if group? do
        GroupApi.get_timestamps(id)
      else
        CypherApi.get_timestamps(id)
      end

    local = NaiveDateTime.local_now()
    utc = NaiveDateTime.utc_now()
    diff = NaiveDateTime.diff(local, utc, :hour)

    Map.update!(timestamps, :inserted_at, fn item ->
      NaiveDateTime.add(item, diff, :hour)
    end)
    |> Map.update!(:updated_at, fn item ->
      NaiveDateTime.add(item, diff, :hour)
    end)
  end

  @doc """
  Recursively builds a decrypted tree structure of a group's contents.

  ## Parameters
  - `id` - The ID of the root group to build the tree from
  - `key` - The encryption key used to decrypt names and content
  - `opts` - Optional keyword list:
    - `:lazy` - Boolean flag for lazy loading:
      - When true, skips downloading and decrypting file contents
      - When false (default), includes full decrypted content

  ## Returns
  - List of items with the structure:
    - For files: `%{data: %{id, name, ext, group, file}}` map
      - When not lazy: includes `blob` with decrypted content
    - For groups: `%{group: {group_info, nested_items}}` tuple
      - `group_info`: `%{id, name, group}` map
      - `nested_items`: Recursive tree structure

  ## Notes
  - Uses depth-first recursion to build nested structures
  - Decrypts both names and content using the provided key
  - For files, handles both metadata and optional content decryption
  - Returns empty list for empty groups
  - Maintains original hierarchy and relationships
  - Performance scales with group size and depth when not lazy
  """
  @spec get_tree(id :: binary(), Keyword.t()) :: MaxGallery.Context.querry()
  def get_tree(id, key, opts \\ []) do
    lazy? = Keyword.get(opts, :lazy)
    {:ok, contents} = get_group(id)

    if contents == [] do
      []
    else
      Enum.map(contents, fn item ->
        if Map.get(item, :ext) do
          {:ok, name} =
            Encrypter.decrypt(
              {item.name_iv, item.name},
              key
            )

          if lazy? do
            %{
              data: %{
                id: item.id,
                name: name,
                ext: item.ext,
                group: item.group_id,
                file: item.file_id
              }
            }
          else
            {:ok, blob} =
              Encrypter.decrypt(
                {item.blob_iv, item.blob},
                key
              )

            %{
              data: %{
                id: item.id,
                name: name,
                blob: blob,
                ext: item.ext,
                group: item.group_id,
                file: item.file_id
              }
            }
          end
        else
          {:ok, name} =
            Encrypter.decrypt(
              {item.name_iv, item.name},
              key
            )

          %{
            group: {
              %{
                id: item.id,
                name: name,
                group: item.group_id
              },
              get_tree(item.id, key, lazy: lazy?)
            }
          }
        end
      end)
    end
  end

  @doc """
  Reconstructs and encrypts a file/group tree for storage in the database.

  ## Parameters
  - `tree` - The tree structure (from get_tree/3) to process
  - `params` - Base parameters to merge with each item's data
  - `fun` - 2-arity callback function that receives:
    - The prepared item parameters
    - Atom specifying item type (:data or :group)
  - `key` - Encryption key for securing all content

  ## Behavior
  For each item in the tree:
  - Files (%{data: data}):
    - Encrypts filename and content
    - Merges with base params
    - Calls fun with :data and prepared params
  - Groups (%{group: {group, subitems}}):
    - Encrypts group name
    - Merges with base params
    - Calls fun with :group
    - Recursively processes subgroups

  ## Notes
  - Uses depth-first traversal
  - Automatically generates and encrypts phantom metadata for all items
  - Maintains original hierarchy through recursive processing
  - The callback function is responsible for persistence
  - Encryption includes:
    - Names for both files and groups
    - Content blobs for files
    - Phantom metadata text
  - Callback receives ready-to-store encrypted parameters
  """
  @spec mount_tree(tree :: tree(), params :: map(), fun :: function(), key :: String.t()) :: any()
  def mount_tree(tree, params, fun, key) when is_function(fun, 2) do
    Enum.each(tree, fn item ->
      case item do
        %{data: data} ->
          {:ok, {name_iv, name}} = Encrypter.encrypt(data.name, key)
          {:ok, {blob_iv, blob}} = Encrypter.encrypt(data.blob, key)

          {:ok, {msg_iv, msg}} =
            Phantom.get_text()
            |> Encrypter.encrypt(key)

          %{
            name: name,
            name_iv: name_iv,
            blob: blob,
            blob_iv: blob_iv,
            msg: msg,
            msg_iv: msg_iv,
            ext: data.ext,
            group_id: data.group,
            file_id: data.file
          }
          |> Map.merge(params)
          |> fun.(:data)

        ## Uses the recursive function to modify an item for insertion, returns nothing in the end. If it’s a group, the returned item will be the `params` field for its child item.

        %{group: {group, subitems}} ->
          {:ok, {name_iv, name}} = Encrypter.encrypt(group.name, key)

          {:ok, {msg_iv, msg}} =
            Phantom.get_text()
            |> Encrypter.encrypt(key)

          sub_params =
            %{name: name, name_iv: name_iv, msg: msg, msg_iv: msg_iv, group_id: group.group}
            |> Map.merge(params)
            |> fun.(:group)

          mount_tree(subitems, sub_params, fun, key)
      end
    end)
  end

  ## Function for extract tree's name and content.
  defp extract_tree(tree) do
    Enum.map(tree, fn item ->
      case item do
        %{data: data} ->
          {data.name <> data.ext, data.blob}

        %{group: {group, subitems}} ->
          {group.name, extract_tree(subitems)}
      end
    end)
  end

  @doc """
  Creates a ZIP archive containing a single encrypted file in a temporary location.

  ## Parameters
  - `name` - The filename (without extension) to use in the archive
  - `blob` - The binary content to compress

  ## Returns
  - `{:ok, path}` on success where:
    - `path` is the full filesystem path to the created ZIP file
  - `{:error, reason}` on failure

  ## Notes
  - Files are stored in `/tmp/max_gallery/zips/`
  - Automatically creates directory structure if needed
  - Appends random suffix to prevent filename collisions
  - Uses Erlang's `:zip` module for compression
  - ZIP contents will contain exactly one file
  - Caller is responsible for cleaning up temporary files
  - Filenames are converted to charlists for Erlang compatibility
  - Does not modify or encrypt the content - assumes already encrypted
  """
  @spec zip_file(name :: String.t(), blob :: binary()) :: {:ok, Path.t()}
  def zip_file(name, blob) do
    zip_path = Variables.tmp_dir() <> "zips/"
    File.mkdir_p(zip_path)

    ## Use `:zip` Erlang module for this operation.
    {:ok, final_path} =
      :zip.create((zip_path <> "#{name}_#{Enum.random(1..999//1)}.zip") |> String.to_charlist(), [
        {
          name |> String.to_charlist(),
          blob
        }
      ])

    {:ok, final_path |> List.to_string()}
  end

  @doc """
  Creates a ZIP archive of an entire folder structure from a decrypted tree.

  ## Parameters
  - `tree` - The hierarchical tree structure (from `get_tree/3`)
  - `group_name` - Base name to use for the output zip file

  ## Returns
  - `{:ok, path}` tuple where:
    - `path` is the full filesystem path to the created ZIP archive
  - `{:error, reason}` if compression fails

  ## Notes
  - Stores archives in `/tmp/max_gallery/zips/` (auto-creates directory)
  - Appends random number (1-1000) to prevent naming conflicts
  - Sanitizes group name by replacing spaces and slashes
  - Preserves full folder structure in the archive
  - Uses `extract_tree/1` and `parse_path/3` internally to:
    - Flatten the hierarchical structure
    - Build proper relative paths for all files
  - Resulting ZIP will mirror the original folder hierarchy
  - Uses Erlang's `:zip` module for compression
  - Maximum archive size depends on available disk space
  """
  @spec zip_folder(tree :: tree(), group_name :: String.t()) :: {:ok, Path.t()}
  def zip_folder(tree, group_name) do
    zip_path = Variables.tmp_dir() <> "zips/"

    File.mkdir_p(zip_path)

    folder =
      (group_name <> "_#{Enum.random(1..1_000)}")
      |> String.replace(" ", "_")
      |> String.replace("/", "//")

    files =
      extract_tree(tree)
      |> parse_path(group_name)

    {:ok, final_path} =
      :zip.create(
        (zip_path <> "#{folder}.zip") |> String.to_charlist(),
        files
      )

    {:ok, final_path |> List.to_string()}
  end

  ## Function to iterate a tree and create a valid file structure for the `:zip` module.
  defp parse_path(tree, folder, back_folder \\ nil)
  defp parse_path([], _folder, _back_folder), do: []

  defp parse_path([head | tail], folder, back_folder) do
    {name, content} = head

    back_folder =
      if back_folder do
        back_folder
      else
        folder
      end

    if is_list(content) do
      parse_path(
        content,
        folder <> "/" <> name,
        back_folder
      )
    else
      [
        {
          (folder <> "/" <> name) |> String.to_charlist(),
          content
        }
      ]
    end ++ parse_path(tail, folder, back_folder)
  end

  @doc """
  Filters a query result by name using case-insensitive pattern matching.

  ## Parameters
  - `query` - Enumerable collection of items to filter
  - `like` - String pattern to match against item names

  ## Returns
  - Filtered list of items where the name matches the pattern

  ## Notes
  - Performs case-insensitive comparison by downcasing both strings
  - Uses regex pattern matching (=~ operator)
  - The pattern can include regex special characters
  - Preserves original item ordering from input query
  - Useful for implementing search functionality
  - More efficient than loading all records then filtering
  """
  @spec get_like(querry :: MaxGallery.Context.querry(), like :: String.t()) ::
          MaxGallery.Context.querry()
  def get_like(querry, like) do
    Enum.filter(querry, fn item ->
      String.downcase(
        item.name
        # Use the `=~` sinal. That represents Regex term.
      ) =~ String.downcase(like)
    end)
  end

  @doc """
  Splits a binary into fixed-size chunks.

  ## Parameters
  - `bin` - The binary data to split
  - `range` - Maximum size (in bytes) for each chunk

  ## Rturns
  - List of binaries where:
    - All chunks except last are exactly `range` bytes
    - Last chunk contains remaining bytes (<= `range`)

  ## Notes
  - Recursively processes the binary
  - Memory efficient (shares underlying binary data)
  - Handles edge cases:
    - Empty binaries
    - Binaries smaller than chunk size
    - Exact multiples of chunk size
  - Uses Erlang's `binary_part/3` and `binary_slice/2`
  """
  @spec binary_chunk(bin :: binary(), range :: pos_integer()) :: [binary()]
  def binary_chunk(bin, range) when byte_size(bin) >= range do
    ## In my mind, this function is O(log n), but my supervisor insists it’s O(n).
    [
      binary_part(bin, 0, range)
      | binary_chunk(
          binary_slice(bin, range..-1//1),
          range
        )
    ]
  end

  def binary_chunk(bin, _range), do: [bin]

  @spec create_folder(folder :: Path.t(), key :: binary(), opts :: Keyword.t()) :: :ok
  def create_folder(folder, key, opts \\ []) do
    group = Keyword.get(opts, :group)
    agent = Keyword.get(opts, :agent)

    {:ok, agent} =
      if agent do
        {:ok, agent}
      else
        Agent.start_link(fn -> %{} end)
      end

    zip_path = Variables.tmp_dir() <> "zips/"
    fpath = Path.relative_to(folder, zip_path)

    exists_path =
      (zip_path <> fpath)
      |> Path.dirname()

    response = find_group(exists_path, agent, exists_path, nil)

    if response do
      {new_group, new_path, persists} = response

      recursive_path(
        new_path ++ [Path.basename(fpath)],
        folder,
        persists,
        agent,
        new_group,
        key
      )
    else
      recursive_path(
        fpath |> String.split("/"),
        folder,
        zip_path,
        agent,
        group,
        key
      )
    end

    :ok
  end

  defp find_group(@zip_path, _agent, _lock, _last), do: nil

  defp find_group(path, agent, lock, last) do
    group =
      Agent.get(agent, & &1)
      |> Map.get(path)

    if group do
      if last do
        {group, Path.relative_to(lock, path) |> Path.split(), path}
      else
        {group, [], path}
      end
    else
      Path.split(path)
      |> Enum.slice(0..-2//1)
      |> Path.join()
      |> find_group(agent, lock, true)
    end
  end

  defp recursive_path([head | []], lock, _persists, _agent, group, key) do
    file = File.read!(lock)

    {:ok, {name_iv, name}} =
      Encrypter.encrypt(
        Path.basename(head, Path.extname(head)),
        key
      )

    {:ok, {msg_iv, msg}} =
      Encrypter.encrypt(
        Phantom.get_text(),
        key
      )

    {:ok, {blob_iv, blob}} =
      Encrypter.encrypt(
        file,
        key
      )

    ext = Path.extname(head)

    ext =
      if ext == "" do
        ".txt"
      else
        ext
      end

    {:ok, %{id: id}} =
      CypherApi.insert(%{
        name: name,
        name_iv: name_iv,
        blob_iv: blob_iv,
        msg: msg,
        msg_iv: msg_iv,
        ext: ext,
        group_id: group
      })

    binary_chunk(blob, Variables.chunk_size())
    |> Cache.insert_chunk(%{
      length: byte_size(file),
      cypher_id: id
    })
  end

  defp recursive_path([head | tail], lock, persists, agent, group, key) do
    {:ok, {name_iv, name}} =
      Encrypter.encrypt(
        head,
        key
      )

    {:ok, {msg_iv, msg}} =
      Encrypter.encrypt(
        Phantom.get_text(),
        key
      )

    {:ok, %{id: id}} =
      GroupApi.insert(%{
        name: name,
        name_iv: name_iv,
        msg: msg,
        msg_iv: msg_iv,
        group_id: group
      })

    new_path =
      Path.join(persists, head)
      |> Path.split()
      |> Path.join()

    exists? =
      Agent.get(agent, & &1)
      |> Map.get(new_path)

    if !exists? do
      Agent.update(agent, fn value ->
        Map.put(
          value,
          new_path,
          id
        )
      end)
    end

    recursive_path(tail, lock, new_path, agent, id, key)
  end

  @spec zip_valid?(path :: Path.t()) :: boolean()
  def zip_valid?(path) do
    String.to_charlist(path)
    |> :zip.zip_open()
    |> case do
      {:ok, pid} ->
        :zip.zip_close(pid)
        true

      {:error, :einval} ->
        false
    end
  end

  @spec gen_code(digits :: pos_integer()) :: String.t()
  def gen_code(digits) when digits > 0 do
    final =
      String.duplicate("9", digits)
      |> String.to_integer()

    Enum.random(1..final//1)
    |> Integer.to_string()
    ## Trailing -> Zero at the end
    ## Leading -> Zero at the begging
    |> String.pad_trailing(digits, "0")
  end

  @spec enc_timestamp(string :: String.t()) :: String.t()
  def enc_timestamp(string) do
    now =
      DateTime.utc_now()
      |> DateTime.to_unix()
      |> to_string()

    token = "#{now}::#{string}"

    {:ok, {iv, enc}} = Encrypter.encrypt(token, System.get_env("ENCRIPT_KEY"))
    Base.url_encode64(iv <> enc)
  end

  @spec dec_timestamp(base :: String.t()) :: {DateTime.t(), String.t()}
  def dec_timestamp(base) do
    ivenc = Base.url_decode64(base)

    if ivenc != :error do
      {:ok, ivenc} = ivenc

      if byte_size(ivenc) > 16 do
        <<iv::binary-size(16), enc::binary>> = ivenc
        {:ok, token} = Encrypter.decrypt({iv, enc}, System.get_env("ENCRIPT_KEY"))

        if byte_size(token) > 12 && String.contains?(token, "::") do
          <<unix_time::binary-size(10), "::", string::binary>> = token

          unix_time = Validate.int(unix_time)

          if unix_time do
            case DateTime.from_unix(unix_time) do
              {:ok, datetime} -> {datetime, string}
              {:error, _reason} -> {:error, "invalid datetime"}
            end
          else
            {:error, "invalid unix time"}
          end
        else
          {:error, "invalid token"}
        end
      else
        {:error, "invalid binary"}
      end
    else
      {:error, "invalid base64"}
    end
  end
end
