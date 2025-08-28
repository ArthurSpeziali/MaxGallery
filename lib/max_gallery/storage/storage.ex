defmodule MaxGallery.Storage do
  @behaviour MaxGallery.Storage.Behaviour

  alias MaxGallery.Request
  alias MaxGallery.Variables
  require Logger

  def put(user, id, blob) do
    key = generate(user, id)

    case Request.storage_put(key, blob) do
      {:ok, _key} ->
        {:ok, key}

      error ->
        error
    end
  end

  def get(user, id) do
    key = generate(user, id)

    case Request.storage_get(key) do
      {:ok, blob} ->
        {:ok, blob}

      error ->
        error
    end
  end

  def del(user, id) do
    key = generate(user, id)

    case Request.storage_delete(key) do
      :ok ->
        :ok

      error ->
        error
    end
  end

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
    case MaxGallery.Storage.BatchDeleter.delete_all_user_files(user) do
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

  defp generate(user, id) do
    if id do
      "#{Variables.gen_clound()}/#{user}/#{id}"
    else
      "#{Variables.gen_clound()}/#{user}"
    end
  end
end
