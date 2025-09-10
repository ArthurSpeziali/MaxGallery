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

  alias ExAws.S3
  alias MaxGallery.Variables
  alias MaxGallery.Utils
  import SweetXml, only: [sigil_x: 2]
  @bucket Variables.bucket_name()

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
  @spec put(user :: binary(), id :: integer(), blob :: binary()) ::
          :ok | {:error, String.t()}
  def put(user, id, blob) do
    key = generate(user, id)
    req = S3.put_object(@bucket, key, blob)

    case ExAws.request(req) do
      {:ok, _status} ->
        :ok

      {:error, {_, _, %{body: xml}}} ->
        {:error, xml_parser(xml)}
    end
  end

  @spec put_stream(user :: binary(), id :: integer(), Path.t() | struct()) :: :ok | {:error, String.t()}
  def put_stream(user, id, path) when is_binary(path) do
    stream = File.stream!(path, Variables.chunk_size() * 5, [:read])

    key = generate(user, id)
    req = S3.upload(stream, @bucket, key)

    case ExAws.request(req) do
      {:ok, _status} ->
        :ok

      {:error, {_, _, %{body: xml}}} ->
        {:error, xml_parser(xml)}
    end
  end

  def put_stream(user, id, stream, part? \\ nil) when is_struct(stream) do
    key = generate(user, id)

    stream = 
      if part? do 
        Stream.flat_map(
          stream, 
          & Utils.binary_chunk(&1, Variables.chunk_size * 5)
        )
      else
        stream
      end
  
    req = S3.upload(stream, @bucket, key)

    case ExAws.request(req) do
      {:ok, _status} ->
        :ok

      {:error, {_, _, %{body: xml}}} ->
        {:error, xml_parser(xml)}
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
  @spec get(user :: binary(), id :: integer()) :: {:ok, binary()} | {:error, String.t()}
  def get(user, id) do
    key = generate(user, id)
    req = S3.get_object(@bucket, key)

    case ExAws.request(req) do
      {:ok, %{body: blob}} ->
        {:ok, blob}

      {:error, {_, _, %{body: xml}}} ->
        {:error, xml_parser(xml)}
    end
  end

  @spec get_stream(user :: binary(), id :: integer(), dest :: Path.t()) :: :ok | {:error, String.t()}
  def get_stream(user, id, dest) when is_binary(dest) do
    key = generate(user, id)

    {ok, res} = 
      try do 
        S3.download_file(@bucket, key, :memory)
        |> ExAws.stream!()
      rescue 
        error ->
          {false, Exception.message(error)}
      else 
        value ->
          {true, value}
      end

    if ok do
      File.open(dest, [:write], fn output -> 
        Enum.each(res, fn chunk -> 
          IO.binwrite(output, chunk)
        end)
      end)

      :ok
    else
      {:error, 
        String.split(res, "\n") |> List.first()
      }
    end
  end

  @spec get_stream(user :: binary(), id :: integer()) :: {:ok, struct()} | {:error, String.t()}
  def get_stream(user, id) do
    key = generate(user, id)

    {ok, res} = 
      try do 
        S3.download_file(@bucket, key, :memory)
        |> ExAws.stream!()
      rescue 
        error ->
          {false, Exception.message(error)}
      else 
        value ->
          {true, value}
      end

    if ok do
      {:ok, res}
    else
      {:error, 
        String.split(res, "\n") |> List.first()
      }
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
  @spec del(user :: binary(), id :: integer()) :: :ok | {:error, String.t()}
  def del(user, id) do
    key = generate(user, id)
    req = S3.delete_object(@bucket, key)

    case ExAws.request(req) do
      {:ok, _status} ->
        :ok

      {:error, {_, _, %{body: xml}}} ->
        {:error, xml_parser(xml)}
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
  @spec exists?(user :: binary(), id :: integer()) :: boolean()
  def exists?(user, id) do
    key = generate(user, id)
    req = S3.head_object(@bucket, key)

    case ExAws.request(req) do
      {:ok, _status} ->
        true

      {:error, _status} ->
        false
    end
  end

  @doc """
  Deletes all files in the encrypted_files folder using batch processing.
  This method handles large numbers of files by processing them in batches
  to avoid API limits (maxFileCount: 25000).

  Returns {:ok, count} where count is the number of successfully deleted files,
  or {:error, reason} if the operation fails.
  """
  @spec del_all(user :: binary()) :: :ok | {:error, String.t()}
  def del_all(user) do
    key = generate(user, nil)

    stream =
      S3.list_objects(@bucket, prefix: key)
      |> ExAws.stream!()
      |> Stream.map(& &1.key)

    req = S3.delete_all_objects(@bucket, stream)

    case ExAws.request(req) do
      {:ok, _status} ->
        :ok

      {:error, {_, _, %{body: xml}}} ->
        {:error, xml_parser(xml)}
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
    key = generate(user, nil)
    req = S3.list_objects(@bucket, prefix: key)

    case ExAws.request(req) do
      {:ok, %{body: %{contents: cont}}} ->
        {:ok, Enum.map(cont, & &1.key)}

      {:error, {_, _, %{body: xml}}} ->
        {:error, xml_parser(xml)}
    end
  end

  # Private function to generate storage keys based on user and file ID
  # Follows the pattern: {cloud_prefix}/{user_id}/{file_id}
  # If no file ID provided, returns user-level path
  defp generate(user, id) do
    if id do
      "#{Variables.gen_clound()}/#{user}/#{id}"
    else
      "#{Variables.gen_clound()}/#{user}/"
    end
  end

  defp xml_parser(xml) do
    SweetXml.parse(xml)
    |> SweetXml.xpath(~x"//Error/Message/text()"s)
  end
end
