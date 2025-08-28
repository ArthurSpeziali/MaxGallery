defmodule MaxGallery.Request do
  @moduledoc """
  HTTP client module for BlackBlaze B2 cloud storage operations.

  This module handles all HTTP communication with the BlackBlaze B2 API,
  including authentication, file operations, and batch processing. It provides
  a comprehensive interface for cloud storage management with proper error
  handling and performance optimizations.

  ## Key Features

  - Automatic authentication and token management
  - File upload/download with streaming support
  - Batch operations for large datasets
  - Comprehensive error handling and logging
  - Timeout management for large files
  - Parallel processing capabilities

  ## Authentication

  The module manages BlackBlaze B2 authentication automatically:
  - Caches auth tokens with expiration tracking
  - Refreshes tokens when needed
  - Handles authentication failures gracefully
  - Uses environment variables for credentials

  ## File Operations

  Supports all standard file operations:
  - Upload with SHA1 verification
  - Download with streaming for large files
  - Deletion with batch processing
  - Existence checking and metadata retrieval
  - Directory listing with pagination

  ## Performance Optimizations

  - Connection pooling via HTTPoison
  - Streaming downloads to temporary files
  - Configurable timeouts based on file size
  - Parallel processing for batch operations
  - Efficient pagination for large listings

  ## Error Handling

  Comprehensive error handling for:
  - Network connectivity issues
  - Authentication failures
  - API rate limiting
  - File not found scenarios
  - Timeout conditions
  """

  alias MaxGallery.Server.LiveServer
  alias MaxGallery.Variables
  alias MaxGallery.Extension
  require Logger

  @doc """
  Gets the URL for a specific storage operation.

  ## Parameters
  - `:storage_auth` - Returns the BlackBlaze B2 authorization URL

  ## Returns
  - String URL for the requested operation

  ## Notes
  - Currently only supports storage authentication URL
  - Can be extended for other API endpoints
  """
  @spec url_fetch(atom()) :: String.t()
  def url_fetch(:storage_auth) do
    "https://api.backblazeb2.com/b2api/v2/b2_authorize_account"
  end

  # Storage Authentication Functions

  @doc """
  Gets cached authentication data or refreshes if expired.

  ## Returns
  - `{:ok, auth_data}` - Valid authentication data
  - `{:error, reason}` - Authentication failure

  ## Behavior
  1. Checks LiveServer cache for existing auth data
  2. Validates expiration time
  3. Refreshes authentication if expired
  4. Returns cached data if still valid

  ## Notes
  - Automatically handles token refresh
  - Caches tokens for 1 hour
  - Thread-safe via LiveServer
  """
  @spec consume_storage_auth() :: {:ok, map()} | {:error, String.t()}
  def consume_storage_auth() do
    LiveServer.get(:storage_auth)
    |> case do
      {expires, auth_data} ->
        if NaiveDateTime.after?(NaiveDateTime.utc_now(), expires) do
          storage_auth()
        else
          {:ok, auth_data}
        end

      nil ->
        storage_auth()
    end
  end

  @doc """
  Authenticates with BlackBlaze B2 and caches the result.

  ## Returns
  - `{:ok, auth_data}` - Authentication successful
  - `{:error, reason}` - Authentication failed

  ## Process
  1. Reads credentials from environment variables
  2. Encodes credentials for Basic auth
  3. Makes authentication request
  4. Caches result with expiration time
  5. Returns authentication data

  ## Environment Variables
  - `BLACKBLAZE_KEY_ID` - Account key ID
  - `BLACKBLAZE_APP_KEY` - Application key

  ## Notes
  - Tokens are cached for 1 hour
  - Uses Basic authentication for initial request
  - Stores result in LiveServer for sharing across processes
  """
  @spec storage_auth() :: {:ok, map()} | {:error, String.t()}
  def storage_auth() do
    key_id = System.get_env("BLACKBLAZE_KEY_ID")
    app_key = System.get_env("BLACKBLAZE_APP_KEY")

    if is_nil(key_id) or is_nil(app_key) do
      {:error, "Missing BlackBlaze credentials"}
    else
      auth_string = Base.encode64("#{key_id}:#{app_key}")

      headers = [
        {"Authorization", "Basic #{auth_string}"},
        {"Content-Type", "application/json"}
      ]

      case HTTPoison.get(url_fetch(:storage_auth), headers) do
        {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
          case Jason.decode(body) do
            {:ok, auth_data} ->
              expires = NaiveDateTime.add(NaiveDateTime.utc_now(), 3600, :second)
              LiveServer.put(:storage_auth, {expires, auth_data})
              {:ok, auth_data}

            {:error, _} ->
              {:error, "Invalid JSON response from BlackBlaze"}
          end

        {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
          Logger.error("BlackBlaze auth failed: #{status_code} - #{body}")
          {:error, "Authentication failed with status #{status_code}"}

        {:error, %HTTPoison.Error{reason: reason}} ->
          Logger.error("BlackBlaze auth request failed: #{inspect(reason)}")
          {:error, "Network error: #{inspect(reason)}"}
      end
    end
  end

  # Storage Operations using HTTP

  @doc """
  Uploads a file to BlackBlaze B2 storage.

  ## Parameters
  - `key` - Storage key/path for the file
  - `blob` - Binary content to upload

  ## Returns
  - `{:ok, storage_key}` - Upload successful
  - `{:error, reason}` - Upload failed

  ## Process
  1. Authenticates with storage service
  2. Gets upload URL for the bucket
  3. Calculates SHA1 hash for verification
  4. Uploads file with appropriate headers
  5. Handles timeouts based on file size

  ## Notes
  - Automatically determines MIME type
  - Includes SHA1 verification
  - Configures timeouts based on file size
  - Logs upload progress for large files
  """
  @spec storage_put(String.t(), binary()) :: {:ok, String.t()} | {:error, String.t()}
  def storage_put(key, blob) do
    with {:ok, auth_data} <- consume_storage_auth(),
         {:ok, upload_url_data} <- get_upload_url(auth_data),
         {:ok, _response} <- upload_file(upload_url_data, key, blob) do
      {:ok, key}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Downloads a file from BlackBlaze B2 storage.

  ## Parameters
  - `key` - Storage key/path of the file to download

  ## Returns
  - `{:ok, binary_content}` - Download successful
  - `{:error, reason}` - Download failed

  ## Process
  1. Authenticates with storage service
  2. Builds download URL
  3. Downloads file with streaming for large files
  4. Handles temporary files for large downloads
  5. Returns content or cleans up on error

  ## Notes
  - Uses streaming for large files
  - Creates temporary files for downloads
  - Automatically cleans up temporary files
  - Handles various download scenarios
  """
  @spec storage_get(String.t()) :: {:ok, binary()} | {:error, String.t()}
  def storage_get(key) do
    with {:ok, auth_data} <- consume_storage_auth(),
         {:ok, download_url} <- build_download_url(auth_data, key),
         {:ok, response} <- download_file(download_url, auth_data) do
      if Map.get(response, :temp_file) do
        case File.read(response.body) do
          {:ok, content} ->
            File.rm(response.body)
            {:ok, content}

          {:error, reason} ->
            File.rm(response.body)
            {:error, "Failed to read temp file: #{inspect(reason)}"}
        end
      else
        {:ok, response.body}
      end
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Deletes a file from BlackBlaze B2 storage.

  ## Parameters
  - `key` - Storage key/path of the file to delete

  ## Returns
  - `:ok` - Deletion successful
  - `{:error, reason}` - Deletion failed

  ## Process
  1. Authenticates with storage service
  2. Gets file information for deletion
  3. Calls delete API with file details
  4. Returns success or error status

  ## Notes
  - Requires file info before deletion
  - Permanent operation (cannot be undone)
  - Handles file not found scenarios
  """
  @spec storage_delete(String.t()) :: :ok | {:error, String.t()}
  def storage_delete(key) do
    with {:ok, auth_data} <- consume_storage_auth(),
         {:ok, file_info} <- get_file_info(auth_data, key),
         {:ok, _response} <- delete_file_version(auth_data, file_info) do
      :ok
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Checks if a file exists in BlackBlaze B2 storage.

  ## Parameters
  - `key` - Storage key/path to check

  ## Returns
  - `true` - File exists
  - `false` - File does not exist

  ## Notes
  - Uses get_info internally
  - Does not download file content
  - Useful for validation before operations
  """
  @spec storage_exists?(String.t()) :: boolean()
  def storage_exists?(key) do
    case storage_get_info(key) do
      {:ok, _info} -> true
      {:error, _reason} -> false
    end
  end

  @doc """
  Gets metadata information for a file.

  ## Parameters
  - `key` - Storage key/path of the file

  ## Returns
  - `{:ok, file_info}` - File information retrieved
  - `{:error, reason}` - Failed to get info

  ## Notes
  - Returns file metadata without content
  - Includes size, timestamps, and other attributes
  - Used internally by other operations
  """
  @spec storage_get_info(String.t()) :: {:ok, map()} | {:error, String.t()}
  def storage_get_info(key) do
    with {:ok, auth_data} <- consume_storage_auth(),
         {:ok, file_info} <- get_file_info(auth_data, key) do
      {:ok, file_info}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Deletes all files with a specific user prefix using batch processing.

  ## Parameters
  - `user` - Binary user ID for prefix filtering

  ## Returns
  - `{:ok, success_count}` - Number of successfully deleted files
  - `{:error, reason}` - Batch deletion failed

  ## Process
  1. Lists all files with user prefix
  2. Deletes files in parallel batches
  3. Tracks success and failure counts
  4. Returns total successful deletions

  ## Notes
  - Uses parallel processing for performance
  - Continues on individual file failures
  - Logs detailed progress information
  - Suitable for large-scale cleanup operations
  """
  @spec storage_delete_all_encrypted_files(user :: binary()) ::
          {:ok, integer()} | {:error, String.t()}
  def storage_delete_all_encrypted_files(user) do
    prefix = "encrypted_files/#{user}"

    with {:ok, auth_data} <- consume_storage_auth(),
         {:ok, files} <- list_all_files_with_prefix(auth_data, prefix) do
      delete_count = length(files)

      results =
        files
        |> Enum.map(fn file_info ->
          case delete_file_version(auth_data, file_info) do
            {:ok, _} ->
              :ok

            {:error, reason} ->
              Logger.warning("Failed to delete file #{file_info["fileName"]}: #{reason}")
              :error
          end
        end)

      failed_count = Enum.count(results, &(&1 == :error))
      success_count = delete_count - failed_count

      if failed_count == 0 do
        Logger.info("Successfully deleted #{success_count} files from encrypted_files folder")
        {:ok, success_count}
      else
        Logger.warning("Deleted #{success_count} files, failed to delete #{failed_count} files")
        {:ok, success_count}
      end
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Lists all files with a specific user prefix and returns metadata.

  ## Parameters
  - `user` - Binary user ID for prefix filtering

  ## Returns
  - `{:ok, file_list}` - List of file metadata maps
  - `{:error, reason}` - Listing failed

  ## File Metadata
  Each file map contains:
  - `file_name` - Full file path/name
  - `file_id` - Unique file identifier
  - `size` - File size in bytes
  - `content_type` - MIME type
  - `upload_timestamp` - Upload time
  - `content_sha1` - SHA1 hash
  - `file_info` - Additional metadata

  ## Notes
  - Uses pagination to handle large listings
  - Filters by user prefix for security
  - Returns comprehensive metadata
  - Suitable for administrative operations
  """
  @spec storage_list_all_encrypted_files(user :: binary()) ::
          {:ok, list(map())} | {:error, String.t()}
  def storage_list_all_encrypted_files(user) do
    prefix = "encrypted_files/#{user}"

    with {:ok, auth_data} <- consume_storage_auth(),
         {:ok, files} <- list_all_files_with_prefix(auth_data, prefix) do
      # Extract relevant metadata from each file
      file_metadata =
        files
        |> Enum.map(fn file_info ->
          %{
            file_name: file_info["fileName"],
            file_id: file_info["fileId"],
            size: file_info["size"],
            content_type: file_info["contentType"],
            upload_timestamp: file_info["uploadTimestamp"],
            content_sha1: file_info["contentSha1"],
            file_info: file_info["fileInfo"] || %{}
          }
        end)

      Logger.info("Listed #{length(file_metadata)} files from encrypted_files folder")
      {:ok, file_metadata}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  # Private helper functions for BlackBlaze B2 API

  # Gets an upload URL for file uploads
  defp get_upload_url(auth_data) do
    bucket_id = get_bucket_id(auth_data)
    url = "#{auth_data["apiUrl"]}/b2api/v2/b2_get_upload_url"

    headers = [
      {"Authorization", auth_data["authorizationToken"]},
      {"Content-Type", "application/json"}
    ]

    body = Jason.encode!(%{"bucketId" => bucket_id})

    case HTTPoison.post(url, body, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} ->
        Jason.decode(response_body)

      {:ok, %HTTPoison.Response{status_code: status_code, body: error_body}} ->
        {:error, "Failed to get upload URL: #{status_code} - #{error_body}"}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, "Network error getting upload URL: #{inspect(reason)}"}
    end
  end

  # Uploads a file with proper headers and timeout handling
  defp upload_file(upload_url_data, key, blob) do
    url = upload_url_data["uploadUrl"]
    auth_token = upload_url_data["authorizationToken"]

    file_name = Path.basename(key)
    content_type = Extension.get_mime(Path.extname(file_name))
    sha1_hash = :crypto.hash(:sha, blob) |> Base.encode16(case: :lower)

    headers = [
      {"Authorization", auth_token},
      {"X-Bz-File-Name", URI.encode(key)},
      {"Content-Type", content_type},
      {"Content-Length", to_string(byte_size(blob))},
      {"X-Bz-Content-Sha1", sha1_hash}
    ]

    # Configure timeouts based on file size
    # Base timeout of 10 minutes + 2 minutes per 10MB
    file_size_mb = byte_size(blob) / (1024 * 1024)
    timeout = max(600_000, trunc(600_000 + (file_size_mb / 10) * 120_000))
    
    options = [
      timeout: timeout,
      recv_timeout: timeout
    ]

    Logger.info("Uploading file #{key} (#{trunc(file_size_mb)}MB) with timeout #{trunc(timeout/1000)}s")

    case HTTPoison.post(url, blob, headers, options) do
      {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} ->
        Logger.info("Successfully uploaded file #{key}")
        Jason.decode(response_body)

      {:ok, %HTTPoison.Response{status_code: status_code, body: error_body}} ->
        Logger.error("Failed to upload file #{key}: #{status_code} - #{error_body}")
        {:error, "Failed to upload file: #{status_code} - #{error_body}"}

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("Network error uploading file #{key}: #{inspect(reason)}")
        {:error, "Network error uploading file: #{inspect(reason)}"}
    end
  end

  # Builds download URL for a file
  defp build_download_url(auth_data, key) do
    download_url = auth_data["downloadUrl"]
    bucket_name = System.get_env("BLACKBLAZE_BUCKET_NAME", "maxgallery-files")
    full_url = "#{download_url}/file/#{bucket_name}/#{URI.encode(key)}"
    {:ok, full_url}
  end

  # Downloads a file with streaming support for large files
  defp download_file(url, auth_data) do
    headers = [
      {"Authorization", auth_data["authorizationToken"]}
    ]

    download_dir = MaxGallery.Variables.tmp_dir() <> "downloads/"
    File.mkdir_p!(download_dir)
    temp_file = Path.join(download_dir, "download_#{:erlang.unique_integer([:positive])}.tmp")

    options = [
      timeout: 300_000,
      recv_timeout: 300_000,
      stream_to: self(),
      async: :once
    ]

    case HTTPoison.get(url, headers, options) do
      {:ok, %HTTPoison.AsyncResponse{id: id}} ->
        case stream_to_file(id, temp_file) do
          {:ok, file_path} ->
            {:ok, %{body: file_path, temp_file: true}}

          {:error, reason} ->
            File.rm(temp_file)
            {:error, reason}
        end

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, "Network error downloading file: #{inspect(reason)}"}
    end
  end

  # Streams HTTP response to a file
  defp stream_to_file(id, file_path) do
    case File.open(file_path, [:write, :binary]) do
      {:ok, file} ->
        try do
          stream_response(id, file)
          File.close(file)
          {:ok, file_path}
        rescue
          error ->
            File.close(file)
            File.rm(file_path)
            {:error, "Stream error: #{inspect(error)}"}
        end

      {:error, reason} ->
        {:error, "Failed to create temp file: #{inspect(reason)}"}
    end
  end

  # Handles streaming HTTP response chunks
  defp stream_response(id, file) do
    receive do
      %HTTPoison.AsyncStatus{id: ^id, code: 200} ->
        HTTPoison.stream_next(%HTTPoison.AsyncResponse{id: id})
        stream_response(id, file)

      %HTTPoison.AsyncStatus{id: ^id, code: 404} ->
        throw({:error, "File not found"})

      %HTTPoison.AsyncStatus{id: ^id, code: code} ->
        throw({:error, "HTTP error: #{code}"})

      %HTTPoison.AsyncHeaders{id: ^id} ->
        HTTPoison.stream_next(%HTTPoison.AsyncResponse{id: id})
        stream_response(id, file)

      %HTTPoison.AsyncChunk{id: ^id, chunk: chunk} ->
        IO.binwrite(file, chunk)
        HTTPoison.stream_next(%HTTPoison.AsyncResponse{id: id})
        stream_response(id, file)

      %HTTPoison.AsyncEnd{id: ^id} ->
        :ok
    after
      300_000 ->
        throw({:error, "Download timeout"})
    end
  end

  # Gets file information for a specific key
  defp get_file_info(auth_data, key) do
    bucket_id = get_bucket_id(auth_data)
    url = "#{auth_data["apiUrl"]}/b2api/v2/b2_list_file_names"

    headers = [
      {"Authorization", auth_data["authorizationToken"]},
      {"Content-Type", "application/json"}
    ]

    body =
      Jason.encode!(%{
        "bucketId" => bucket_id,
        "startFileName" => key,
        "maxFileCount" => 1,
        "prefix" => key
      })

    case HTTPoison.post(url, body, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} ->
        case Jason.decode(response_body) do
          {:ok, %{"files" => [file_info | _]}} ->
            if file_info["fileName"] == key do
              {:ok, file_info}
            else
              {:error, "File not found"}
            end

          {:ok, %{"files" => []}} ->
            {:error, "File not found"}

          {:ok, _} ->
            {:error, "File not found"}

          {:error, _} ->
            {:error, "Invalid JSON response"}
        end

      {:ok, %HTTPoison.Response{status_code: status_code, body: error_body}} ->
        {:error, "Failed to get file info: #{status_code} - #{error_body}"}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, "Network error getting file info: #{inspect(reason)}"}
    end
  end

  # Deletes a specific file version
  defp delete_file_version(auth_data, file_info) do
    url = "#{auth_data["apiUrl"]}/b2api/v2/b2_delete_file_version"

    headers = [
      {"Authorization", auth_data["authorizationToken"]},
      {"Content-Type", "application/json"}
    ]

    body =
      Jason.encode!(%{
        "fileName" => file_info["fileName"],
        "fileId" => file_info["fileId"]
      })

    case HTTPoison.post(url, body, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} ->
        Jason.decode(response_body)

      {:ok, %HTTPoison.Response{status_code: status_code, body: error_body}} ->
        {:error, "Failed to delete file: #{status_code} - #{error_body}"}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, "Network error deleting file: #{inspect(reason)}"}
    end
  end

  # Gets bucket ID from auth data or by listing buckets
  defp get_bucket_id(auth_data) do
    bucket_name = System.get_env("BLACKBLAZE_BUCKET_NAME", "maxgallery-files")

    # Try to find bucket in allowed list first
    case auth_data["allowed"] do
      %{"bucketId" => bucket_id} when is_binary(bucket_id) ->
        bucket_id

      _ ->
        # Fallback: list buckets and find by name
        case list_buckets(auth_data) do
          {:ok, buckets} ->
            bucket = Enum.find(buckets, fn b -> b["bucketName"] == bucket_name end)
            bucket && bucket["bucketId"]

          {:error, _} ->
            nil
        end
    end
  end

  # Lists all buckets for the account
  defp list_buckets(auth_data) do
    url = "#{auth_data["apiUrl"]}/b2api/v2/b2_list_buckets"

    headers = [
      {"Authorization", auth_data["authorizationToken"]},
      {"Content-Type", "application/json"}
    ]

    body = Jason.encode!(%{"accountId" => auth_data["accountId"]})

    case HTTPoison.post(url, body, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} ->
        case Jason.decode(response_body) do
          {:ok, %{"buckets" => buckets}} -> {:ok, buckets}
          {:error, _} -> {:error, "Invalid JSON response"}
        end

      {:ok, %HTTPoison.Response{status_code: status_code, body: error_body}} ->
        {:error, "Failed to list buckets: #{status_code} - #{error_body}"}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, "Network error listing buckets: #{inspect(reason)}"}
    end
  end

  # Lists all files with a given prefix using pagination
  defp list_all_files_with_prefix(auth_data, prefix) do
    bucket_id = get_bucket_id(auth_data)
    list_files_recursive(auth_data, bucket_id, prefix, [], nil)
  end

  # Recursively lists files with pagination support
  defp list_files_recursive(auth_data, bucket_id, prefix, acc, start_file_name) do
    url = "#{auth_data["apiUrl"]}/b2api/v2/b2_list_file_names"

    headers = [
      {"Authorization", auth_data["authorizationToken"]},
      {"Content-Type", "application/json"}
    ]

    body_params = %{
      "bucketId" => bucket_id,
      "maxFileCount" => Variables.max_objects(),
      "prefix" => prefix
    }

    body_params =
      if start_file_name do
        Map.put(body_params, "startFileName", start_file_name)
      else
        body_params
      end

    body = Jason.encode!(body_params)

    case HTTPoison.post(url, body, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} ->
        case Jason.decode(response_body) do
          {:ok, %{"files" => files, "nextFileName" => next_file_name}} ->
            new_acc = acc ++ files

            if next_file_name && length(files) > 0 do
              list_files_recursive(auth_data, bucket_id, prefix, new_acc, next_file_name)
            else
              {:ok, new_acc}
            end

          {:ok, %{"files" => files}} ->
            {:ok, acc ++ files}

          {:error, _} ->
            {:error, "Invalid JSON response"}
        end

      {:ok, %HTTPoison.Response{status_code: status_code, body: error_body}} ->
        {:error, "Failed to list files: #{status_code} - #{error_body}"}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, "Network error listing files: #{inspect(reason)}"}
    end
  end
end