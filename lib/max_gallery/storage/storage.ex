defmodule MaxGallery.Storage do
  @behaviour MaxGallery.Storage.Behaviour
  
  alias MaxGallery.Request
  alias MaxGallery.Variables
  require Logger

  def put(cypher_id, blob) do
    key = generate(cypher_id)

    case Request.storage_put(key, blob) do
      {:ok, _key} ->
        {:ok, key}

      error ->
        error
    end
  end

  def get(cypher_id) do
    key = generate(cypher_id)

    case Request.storage_get(key) do
      {:ok, blob} ->
        {:ok, blob}

      error ->
        error
    end
  end

  def del(cypher_id \\ nil) do
    key = generate(cypher_id)

    case Request.storage_delete(key) do
      :ok ->
        :ok

      error ->
        error
    end
  end

  def exists?(cypher_id) do
    key = generate(cypher_id)
    Request.storage_exists?(key)
  end

  @doc """
  Deletes all files in the encrypted_files folder.
  Returns {:ok, count} where count is the number of successfully deleted files,
  or {:error, reason} if the operation fails.
  """
  @spec del_all() :: {:ok, integer()} | {:error, String.t()}
  def del_all() do
    case Request.storage_delete_all_encrypted_files() do
      {:ok, count} ->
        Logger.info("Storage.delete_all_encrypted_files: Successfully deleted #{count} files")
        {:ok, count}

      {:error, reason} ->
        Logger.error("Storage.delete_all_encrypted_files: Failed with reason: #{reason}")
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
  @spec list() :: {:ok, list(map())} | {:error, String.t()}
  def list() do
    case Request.storage_list_all_encrypted_files() do
      {:ok, files} ->
        {:ok, files}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp generate(cypher_id) do
    if cypher_id do
      "#{Variables.gen_clound()}/#{cypher_id}"
    else
      "#{Variables.gen_clound()}"
    end
  end
end
