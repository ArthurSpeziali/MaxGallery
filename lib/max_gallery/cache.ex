defmodule MaxGallery.Cache do
  @moduledoc """
  Simplified cache system for decrypted files from S3 storage.

  This module replaces the old chunk-based system in the database,
  maintaining only a temporary cache of decrypted files in the local filesystem.

  ## Key Features

  - Temporary file caching for performance optimization
  - Automatic cache management and cleanup
  - Memory and disk-based content retrieval
  - User-scoped cache isolation
  - Integration with encryption/decryption pipeline

  ## Cache Strategy

  The cache operates as follows:
  1. Check if file exists in local cache
  2. If not cached, download from storage and decrypt
  3. Store decrypted content in temporary file
  4. Return file path or content based on request type
  5. Automatic cleanup of old files

  ## File Organization

  Cache files are stored with the pattern:
  `{tmp_dir}/cache/{user}_{env}_{file_id}`

  This ensures:
  - User isolation
  - Environment separation
  - Unique file identification
  - Easy cleanup and management

  ## Performance Benefits

  - Reduces repeated decryption operations
  - Minimizes storage API calls
  - Enables efficient streaming for large files
  - Supports both memory and disk-based access patterns
  """

  alias MaxGallery.StorageAdapter, as: Storage
  alias MaxGallery.Utils
  alias MaxGallery.Encrypter
  alias MaxGallery.Phantom
  alias MaxGallery.Variables

  # Private function to get the appropriate temporary path based on environment
  defp tmp_path() do
    if Mix.env() == :dev do
      Variables.tmp_dir() <> "cache/"
    else
      Variables.tmp_dir() <> "test/"
    end
  end

  @doc """
  Gets a decrypted file, using cache if available or downloading from S3.

  ## Parameters
  - `user` - Binary user ID for cache isolation
  - `id` - File ID to retrieve
  - `blob_iv` - IV used to decrypt the blob
  - `key` - Decryption key

  ## Returns
  - `{path, was_downloaded}` - Tuple with file path and boolean indicating if it was downloaded

  ## Behavior
  1. Checks if file exists in cache
  2. If cached and key is valid, returns existing path
  3. If not cached, downloads and decrypts from storage
  4. Stores in cache and returns new path

  ## Notes
  - Uses Phantom validation to verify key authenticity
  - Returns boolean flag indicating whether download occurred
  - Automatically creates cache directory if needed
  """
  @spec consume_cache(user :: binary(), id :: integer(), blob_iv :: binary(), key :: String.t(), length :: integer()) :: {Path.t(), boolean()}
  def consume_cache(user, id, blob_iv, key, length) do
    path = get_path(user, id)

    if File.exists?(path) && Phantom.insert_line?(user, key) do
      {path, false}
    else
      write_chunk(user, id, blob_iv, key, length)
      {path, true}
    end
  end

  # Backward compatibility function
  def consume_cache(user, id, blob_iv, key) do
    # Default to using stream for backward compatibility
    consume_cache(user, id, blob_iv, key, Variables.chunk_size() * 2)
  end

  @doc """
  Downloads file from S3, decrypts it and writes to cache.

  ## Parameters
  - `user` - Binary user ID for storage path generation
  - `id` - File ID to download
  - `blob_iv` - IV used to decrypt the blob
  - `key` - Decryption key

  ## Returns
  - File path where the decrypted content was written

  ## Process
  1. Generates cache file path
  2. Creates cache directory if needed
  3. Downloads encrypted blob from storage
  4. Decrypts blob using provided IV and key
  5. Writes decrypted content to cache file
  6. Returns cache file path

  ## Notes
  - Overwrites existing cache files
  - Creates parent directories automatically
  - Uses binary write mode for efficiency
  """
  @spec write_chunk(user :: binary(), id :: integer(), blob_iv :: binary(), key :: String.t(), length :: integer()) :: Path.t()
  def write_chunk(user, id, blob_iv, key, length) do
    file_path = get_path(user, id)
    File.mkdir_p!(tmp_path())

    if Variables.use_stream() <= length do
      # Use streaming for large files
      {:ok, stream} = Storage.get_stream(user, id)
      out_stream = Encrypter.decrypt_stream(stream, blob_iv, key)
      Utils.exec(out_stream, :write, {file_path})
    else
      # Use normal get/decrypt for small files
      {:ok, encrypted_blob} = Storage.get(user, id)
      decrypted_blob = Encrypter.decrypt(encrypted_blob, blob_iv, key)
      File.write!(file_path, decrypted_blob)
    end
    
    file_path
  end

  # Backward compatibility function
  def write_chunk(user, id, blob_iv, key) do
    # Default to using stream for backward compatibility
    write_chunk(user, id, blob_iv, key, Variables.chunk_size() * 2)
  end

  @doc """
  Gets decrypted content directly in memory from S3.

  ## Parameters
  - `user` - Binary user ID for cache management
  - `id` - File ID to retrieve
  - `blob_iv` - IV used to decrypt the blob
  - `key` - Decryption key

  ## Returns
  - `{:ok, decrypted_content}` - Decrypted file content in memory
  - `{:error, reason}` - Error if file read fails

  ## Behavior
  1. Uses consume_cache to ensure file is available locally
  2. Reads entire file content into memory
  3. Returns binary content for immediate use

  ## Notes
  - Suitable for small to medium files
  - Loads entire content into memory
  - May trigger download if not cached
  - More memory intensive than streaming approaches
  """
  @spec get_content(user :: binary(), id :: integer(), blob_iv :: binary(), key :: String.t(), length :: integer()) :: binary()
  def get_content(user, id, blob_iv, key, length) do
    if Variables.use_stream() <= length do
      # Use cache for large files
      {path, _created} = consume_cache(user, id, blob_iv, key, length)
      File.read!(path)
    else
      # Direct decrypt for small files (no cache needed)
      {:ok, encrypted_blob} = Storage.get(user, id)
      Encrypter.decrypt(encrypted_blob, blob_iv, key)
    end
  end

  # Backward compatibility function
  def get_content(user, id, blob_iv, key) do
    # Default to using stream for backward compatibility
    get_content(user, id, blob_iv, key, Variables.chunk_size() * 2)
  end

  @doc """
  Removes a file from cache.

  ## Parameters
  - `user` - Binary user ID for path generation
  - `id` - File ID to remove from cache

  ## Returns
  - `:ok` - Always returns ok, even if file doesn't exist

  ## Notes
  - Safe operation that doesn't fail if file is missing
  - Only removes from local cache, not from storage
  - Useful for cache invalidation after updates
  """
  @spec remove_cache(user :: binary(), id :: integer()) :: :ok
  def remove_cache(user, id) do
    path = get_path(user, id)

    if File.exists?(path) do
      File.rm!(path)
    end

    :ok
  end

  @doc """
  Checks if a file exists in cache.

  ## Parameters
  - `user` - Binary user ID for path generation
  - `id` - File ID to check

  ## Returns
  - `true` - File exists in cache
  - `false` - File not in cache

  ## Notes
  - Only checks local cache, not storage
  - Useful for cache hit/miss analysis
  - Does not validate file integrity
  """
  @spec cached?(user :: binary(), id :: integer()) :: boolean()
  def cached?(user, id) do
    path = get_path(user, id)
    File.exists?(path)
  end

  @doc """
  Gets the cache path for a file.

  ## Parameters
  - `user` - Binary user ID for path generation
  - `id` - File ID for path generation

  ## Returns
  - String path to the cache file

  ## Notes
  - Generates consistent paths for the same user/id combination
  - Includes environment in path for isolation
  - Does not check if file actually exists
  """
  @spec get_path(user :: binary(), id :: integer()) :: Path.t()
  def get_path(user, id) do
    tmp_path() <> "#{user}_#{Mix.env()}_#{id}"
  end

  @doc """
  Reads cached file content directly.

  ## Parameters
  - `user` - Binary user ID for path generation
  - `id` - File ID to read

  ## Returns
  - Binary content if file exists in cache
  - `:error` if file not in cache

  ## Notes
  - Only reads from cache, does not download
  - Returns raw binary content
  - Fails if file not cached
  """
  @spec get_cache(user :: binary(), id :: integer()) :: binary() | :error
  def get_cache(user, id) do
    path = get_path(user, id)

    if cached?(user, id) do
      File.read!(path)
    else
      :error
    end
  end

  @doc """
  Removes all cache files for a specific user.

  ## Parameters
  - `user` - Binary user ID whose cache files should be removed

  ## Returns
  - `{:ok, count}` - Number of files removed
  - `{:error, reason}` - Error if directory listing fails

  ## Process
  1. Creates cache directory if it doesn't exist
  2. Lists all files in cache directory
  3. Filters files that belong to the specified user
  4. Removes matching files
  5. Returns count of removed files

  ## Notes
  - Matches files with pattern: `{user}_{env}_{file_id}`
  - Safe to call even if no files exist for the user
  - Gracefully handles permission errors on individual files
  - Used during logout to clean up user-specific cache
  """
  @spec cleanup(user :: binary()) :: {:ok, non_neg_integer()} | {:error, any()}
  def cleanup(user) do
    File.mkdir_p!(tmp_path())

    case File.ls(tmp_path()) do
      {:ok, files} ->
        user_prefix = "#{user}_#{Mix.env()}_"

        removed_count =
          files
          |> Enum.filter(&String.starts_with?(&1, user_prefix))
          |> Enum.reduce(0, fn file, acc ->
            file_path = Path.join(tmp_path(), file)

            case File.rm(file_path) do
              :ok -> acc + 1
              # Continue even if individual file removal fails
              {:error, _reason} -> acc
            end
          end)

        {:ok, removed_count}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Cleans up old cache files.
  Removes files older than the specified age in minutes.

  ## Parameters
  - `max_age_minutes` - Maximum age in minutes (default: 120)

  ## Returns
  - `:ok` - Always returns ok

  ## Process
  1. Creates cache directory if it doesn't exist
  2. Lists all files in cache directory
  3. Checks modification time of each file
  4. Removes files older than specified age
  5. Handles errors gracefully

  ## Notes
  - Uses file modification time for age calculation
  - Gracefully handles missing files or permission errors
  - Runs automatically via GarbageServer
  - Safe to call repeatedly
  """
  @spec cleanup_old_files(non_neg_integer()) :: :ok
  def cleanup_old_files(max_age_minutes \\ 120) do
    File.mkdir_p!(tmp_path())

    case File.ls(tmp_path()) do
      {:ok, files} ->
        now_gregorian = :calendar.datetime_to_gregorian_seconds(:calendar.universal_time())
        max_age_seconds = max_age_minutes * 60

        Enum.each(files, fn file ->
          file_path = Path.join(tmp_path(), file)

          case File.stat(file_path) do
            {:ok, %{mtime: mtime}} ->
              file_time_gregorian = :calendar.datetime_to_gregorian_seconds(mtime)
              file_age = now_gregorian - file_time_gregorian

              if file_age > max_age_seconds do
                File.rm(file_path)
              end

            _ ->
              :ok
          end
        end)

      _ ->
        :ok
    end

    :ok
  end


end
