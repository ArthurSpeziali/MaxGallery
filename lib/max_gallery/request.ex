defmodule MaxGallery.Request do
  alias MaxGallery.Server.LiveServer
  alias MaxGallery.Variables
  alias MaxGallery.Extension
  require Logger

  @spec url_fetch(atom()) :: String.t()
  def url_fetch(:storage_auth) do
    "https://api.backblazeb2.com/b2api/v2/b2_authorize_account"
  end

  # Storage Authentication Functions
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

  @spec storage_exists?(String.t()) :: boolean()
  def storage_exists?(key) do
    case storage_get_info(key) do
      {:ok, _info} -> true
      {:error, _reason} -> false
    end
  end

  @spec storage_get_info(String.t()) :: {:ok, map()} | {:error, String.t()}
  def storage_get_info(key) do
    with {:ok, auth_data} <- consume_storage_auth(),
         {:ok, file_info} <- get_file_info(auth_data, key) do
      {:ok, file_info}
    else
      {:error, reason} -> {:error, reason}
    end
  end

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

  defp build_download_url(auth_data, key) do
    download_url = auth_data["downloadUrl"]
    bucket_name = System.get_env("BLACKBLAZE_BUCKET_NAME", "maxgallery-files")
    full_url = "#{download_url}/file/#{bucket_name}/#{URI.encode(key)}"
    {:ok, full_url}
  end

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

  defp list_all_files_with_prefix(auth_data, prefix) do
    bucket_id = get_bucket_id(auth_data)
    list_files_recursive(auth_data, bucket_id, prefix, [], nil)
  end

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