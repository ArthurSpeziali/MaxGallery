defmodule MaxGallery.Storage do
  @moduledoc """
  Main storage interface for encrypted file operations using cloud storage.

  This module provides a high-level API for storing, retrieving, and managing
  encrypted files in cloud storage (BlackBlaze B2). It acts as an adapter layer
  between the application and the underlying storage service.

  ## Key Features

  - Secure file storage with user-scoped paths
  - Batch deletion operations for large datasets
  - File existence checking and metadata retrieval
  - Automatic path generation based on user and file ID
  - Integration with storage authentication and request handling

  ## Storage Structure

  Files are stored using a hierarchical path structure:
  `{cloud_prefix}/{user_id}/{file_id}`

  This ensures:
  - User isolation and security
  - Efficient organization and retrieval
  - Support for user-specific operations

  ## Error Handling

  All operations return standardized tuples:
  - `{:ok, result}` for successful operations
  - `{:error, reason}` for failures

  The module handles various failure scenarios including:
  - Network connectivity issues
  - Authentication failures
  - Storage service errors
  - Invalid file operations
  """

  @behaviour MaxGallery.Storage.Behaviour

  alias MaxGallery.Request
  alias MaxGallery.Variables
  require Logger

  @doc """
  Stores an encrypted file blob in cloud storage.

  ## Parameters
  - `user` - Binary user ID for path generation
  - `id` - Binary file ID for unique identification
  - `blob` - Binary content to store (should already be encrypted)

  ## Returns
  - `{:ok, storage_key}` - Success with the generated storage key
  - `{:error, reason}` - Failure with error description

  ## Notes
  - Automatically generates storage path using user and file ID
  - Delegates actual storage operation to Request module
  - Does not perform encryption (expects pre-encrypted content)
  """
  @spec put(user :: binary(), id :: binary(), blob :: binary()) ::
          {:ok, String.t()} | {:error, String.t()}
  def put(user, id, blob) do
    key = generate(user, id)

    case Request.storage_put(key, blob) do
      {:ok, _key} ->
        {:ok, key}

      error ->
        error
    end
  end

  @doc """
  Retrieves an encrypted file blob from cloud storage.

  ## Parameters
  - `user` - Binary user ID for path generation
  - `id` - Binary file ID to retrieve

  ## Returns
  - `{:ok, blob}` - Success with the encrypted file content
  - `{:error, reason}` - Failure with error description

  ## Notes
  - Automatically generates storage path using user and file ID
  - Returns encrypted content (caller responsible for decryption)
  - Delegates actual retrieval to Request module
  """
  @spec get(user :: binary(), id :: binary()) :: {:ok, binary()} | {:error, String.t()}
  def get(user, id) do
    key = generate(user, id)

    case Request.storage_get(key) do
      {:ok, blob} ->
        {:ok, blob}

      error ->
        error
    end
  end

  @doc """
  Deletes a single encrypted file from cloud storage.

  ## Parameters
  - `user` - Binary user ID for path generation
  - `id` - Binary file ID to delete

  ## Returns
  - `:ok` - Success
  - `{:error, reason}` - Failure with error description

  ## Notes
  - Automatically generates storage path using user and file ID
  - Permanent operation (cannot be undone)
  - Delegates actual deletion to Request module
  """
  @spec del(user :: binary(), id :: binary()) :: :ok | {:error, String.t()}
  def del(user, id) do
    key = generate(user, id)

    case Request.storage_delete(key) do
      :ok ->
        :ok

      error ->
        error
    end
  end

  @doc """
  Checks if a file exists in cloud storage.

  ## Parameters
  - `user` - Binary user ID for path generation
  - `id` - Binary file ID to check

  ## Returns
  - `true` - File exists
  - `false` - File does not exist

  ## Notes
  - Automatically generates storage path using user and file ID
  - Does not retrieve file content, only checks existence
  - Useful for validation before operations
  """
  @spec exists?(user :: binary(), id :: binary()) :: boolean()
  def exists?(user, id) do
    key = generate(user, id)
    Request.storage_exists?(key)
  end

  @doc """
  Deletes all files in the encrypted_files folder using batch processing.
  This method handles large numbers of files by processing them in batches
  to avoid API limits (maxFileCount: 25000).

  Returns {:ok, count} where count is the number of successfully deleted files,
  or {:error, reason} if the operation fails.
  """
  @spec del_all(user :: binary()) :: {:ok, integer()} | {:error, String.t()}
  def del_all(user) do
    case MaxGallery.Storage.Deleter.delete_all_user_files(user) do
      {:ok, count} ->
        Logger.info(
          "Storage.delete_all_encrypted_files: Successfully deleted #{count} files from #{user} user using batch processing"
        )

        {:ok, count}

      {:error, reason} ->
        Logger.error(
          "Storage.delete_all_encrypted_files: Failed with reason: #{reason} from #{user} user"
        )

        {:error, reason}
    end
  end

  @doc """
  Lists all files in the encrypted_files folder with their metadata.
  Returns {:ok, files} where files is a list of maps containing file metadata,
  or {:error, reason} if the operation fails.

  Each file map contains:
  - file_name: The full file path/name
  - file_id: Unique file identifier
  - size: File size in bytes
  - content_type: MIME type of the file
  - upload_timestamp: When the file was uploaded (timestamp)
  - content_sha1: SHA1 hash of the file content
  - file_info: Additional metadata map
  """
  @spec list(user :: binary()) :: {:ok, list(map())} | {:error, String.t()}
  def list(user) do
    case Request.storage_list_all_encrypted_files(user) do
      {:ok, files} ->
        {:ok, files}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Private function to generate storage keys based on user and file ID
  # Follows the pattern: {cloud_prefix}/{user_id}/{file_id}
  # If no file ID provided, returns user-level path
  defp generate(user, id) do
    if id do
      "#{Variables.gen_clound()}/#{user}/#{id}"
    else
      "#{Variables.gen_clound()}/#{user}"
    end
  end
end