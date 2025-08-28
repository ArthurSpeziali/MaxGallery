defmodule MaxGallery.Cache do
  @moduledoc """
  Simplified cache system for decrypted files from S3 storage.

  This module replaces the old chunk-based system in the database,
  maintaining only a temporary cache of decrypted files in the local filesystem.
  """

  alias MaxGallery.StorageAdapter, as: Storage
  alias MaxGallery.Encrypter
  alias MaxGallery.Phantom
  alias MaxGallery.Variables

  @tmp_path Variables.tmp_dir() <> "cache/"

  @doc """
  Gets a decrypted file, using cache if available or downloading from S3.

  ## Parameters
  - `id`: File ID
  - `blob_iv`: IV used to decrypt the blob
  - `key`: Decryption key

  ## Returns
  - `{path, was_downloaded}`: Tuple with file path and boolean indicating if it was downloaded
  """
  @spec consume_cache(user :: binary(), binary(), binary(), String.t()) :: {Path.t(), boolean()}
  def consume_cache(user, id, blob_iv, key) do
    path = get_path(user, id)

    if File.exists?(path) && Phantom.insert_line?(user, key) do
      {path, false}
    else
      write_chunk(user, id, blob_iv, key)
      {path, true}
    end
  end

  @doc """
  Downloads file from S3, decrypts it and writes to cache.

  ## Parameters
  - `id`: File ID
  - `blob_iv`: IV used to decrypt the blob
  - `key`: Decryption key

  ## Returns
  - File path where the decrypted content was written
  """
  @spec write_chunk(user :: binary(), binary(), binary(), String.t()) :: Path.t()
  def write_chunk(user, id, blob_iv, key) do
    file_path = get_path(user, id)
    File.mkdir_p!(@tmp_path)

    {:ok, enc_blob} = Storage.get(user, id)
    {:ok, blob} = Encrypter.decrypt({blob_iv, enc_blob}, key)

    File.write!(file_path, blob, [:write])
    file_path
  end

  @doc """
  Gets decrypted content directly in memory from S3.

  ## Parameters
  - `id`: File ID
  - `blob_iv`: IV used to decrypt the blob
  - `key`: Decryption key

  ## Returns
  - `{:ok, decrypted_content}`: Decrypted file content
  """
  @spec get_content(user :: binary(), binary(), binary(), String.t()) ::
          {:ok, binary()} | {:error, any()}
  def get_content(user, id, blob_iv, key) do
    {path, _created} = consume_cache(user, id, blob_iv, key)
    File.read(path)
  end

  @doc """
  Encodes a file chunk using Phantom validation.
  This function is kept for compatibility with existing code.
  """
  @spec encode_chunk(Path.t()) :: Path.t()
  def encode_chunk(path) do
    File.open!(path <> "_encode", [:write], fn output ->
      File.stream!(path, [], Variables.chunk_size())
      |> Stream.each(fn chunk ->
        encoded_data = Phantom.validate_bin(chunk)
        IO.binwrite(output, encoded_data)
      end)
      |> Stream.run()
    end)

    File.rm!(path)
    inspect(Mix.env()) <> "_" <> path <> "_encode"
  end

  @doc """
  Removes a file from cache.
  """
  @spec remove_cache(binary(), binary()) :: :ok
  def remove_cache(user, id) do
    path = get_path(user, id)

    if File.exists?(path) do
      File.rm!(path)
    end

    :ok
  end

  @doc """
  Checks if a file exists in cache.
  """
  @spec cached?(user :: binary(), binary()) :: Path.t()
  def cached?(user, id) do
    path = get_path(user, id)
    File.exists?(path)
  end

  @doc """
  Gets the cache path for a file.
  """
  @spec get_path(user :: binary(), binary()) :: Path.t()
  def get_path(user, id) do
    @tmp_path <> "#{user}_#{Mix.env()}_#{id}"
  end

  @spec get_cache(user :: binary(), binary()) :: binary() | :error
  def get_cache(user, id) do
    path = get_path(user, id)

    if cached?(user, id) do
      File.read!(path)
    else
      :error
    end
  end

  @doc """
  Cleans up old cache files.
  Removes files older than the specified age in minutes.
  """
  @spec cleanup_old_files(non_neg_integer()) :: :ok
  def cleanup_old_files(max_age_minutes \\ 120) do
    File.mkdir_p!(@tmp_path)

    case File.ls(@tmp_path) do
      {:ok, files} ->
        now_gregorian = :calendar.datetime_to_gregorian_seconds(:calendar.universal_time())
        max_age_seconds = max_age_minutes * 60

        Enum.each(files, fn file ->
          file_path = Path.join(@tmp_path, file)

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
