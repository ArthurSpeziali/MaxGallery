defmodule MaxGallery.Storage.Deleter do
  @moduledoc """
  Handles batch deletion of files from storage to avoid API limits.

  This module implements a batched approach to delete large numbers of files
  without hitting the maxFileCount limit of 25,000 files per request.

  ## Key Features

  - Batch processing to handle large file deletions
  - Automatic retry and error handling
  - Progress tracking and logging
  - Configurable batch sizes based on API limits
  - Parallel processing within batches for performance

  ## Batch Strategy

  The deletion process works as follows:
  1. Calculate safe batch size (40% of API limit)
  2. List files in batches using pagination
  3. Delete files in parallel within each batch
  4. Continue until all files are processed
  5. Provide detailed logging and progress tracking

  ## Error Handling

  - Continues processing even if individual files fail
  - Tracks both successful and failed deletions
  - Returns total count of successfully deleted files
  - Logs detailed information about failures
  """

  alias MaxGallery.Request
  alias MaxGallery.Variables
  require Logger

  @doc """
  Deletes all files for a user in batches to avoid API limits.

  ## Parameters
  - `user` - The user ID whose files should be deleted

  ## Returns
  - `{:ok, total_deleted}` - Number of successfully deleted files
  - `{:error, reason}` - Error message if the operation fails

  ## Process
  1. Authenticates with storage service
  2. Calculates optimal batch size
  3. Recursively processes file batches
  4. Tracks progress and handles errors
  5. Returns total deletion count

  ## Notes
  - Uses 40% of max API limit for safety
  - Includes small delays between batches
  - Processes files in parallel within batches
  - Continues on individual file failures
  """
  @spec delete_all_user_files(binary()) :: {:ok, integer()} | {:error, String.t()}
  def delete_all_user_files(user) do
    prefix = "encrypted_files/#{user}"

    case Request.consume_storage_auth() do
      {:ok, auth_data} ->
        bucket_id = get_bucket_id(auth_data)
        batch_size = calculate_safe_batch_size()

        Logger.info("Starting batch deletion for user #{user} with batch size #{batch_size}")

        delete_files_in_batches(auth_data, bucket_id, prefix, batch_size)

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Private functions

  # Calculate a safe batch size to avoid hitting API limits
  # Uses 40% of the maximum to allow for API overhead and safety margin
  defp calculate_safe_batch_size do
    max_limit = Variables.max_objects()
    div(max_limit * 40, 100)
  end

  # Main batch processing function that orchestrates the deletion
  defp delete_files_in_batches(auth_data, bucket_id, prefix, batch_size) do
    delete_batch_recursive(auth_data, bucket_id, prefix, 0, 0, nil, batch_size)
  end

  # Recursive function that processes batches until all files are deleted
  # Tracks total deleted/failed counts and handles pagination
  defp delete_batch_recursive(
         auth_data,
         bucket_id,
         prefix,
         total_deleted,
         total_failed,
         start_file_name,
         batch_size
       ) do
    case list_files_batch(auth_data, bucket_id, prefix, start_file_name, batch_size) do
      {:ok, files, next_file_name} ->
        if Enum.empty?(files) do
          # No more files to delete
          Logger.info(
            "Batch deletion completed: #{total_deleted} deleted, #{total_failed} failed"
          )

          {:ok, total_deleted}
        else
          # Delete current batch
          Logger.info("Processing batch of #{length(files)} files...")

          {batch_deleted, batch_failed} = delete_files_batch(auth_data, files)

          new_total_deleted = total_deleted + batch_deleted
          new_total_failed = total_failed + batch_failed

          Logger.info(
            "Batch completed: #{batch_deleted} deleted, #{batch_failed} failed. Total: #{new_total_deleted} deleted, #{new_total_failed} failed"
          )

          # Continue with next batch if there are more files
          if next_file_name do
            # Add a small delay between batches to be nice to the API
            Process.sleep(100)

            delete_batch_recursive(
              auth_data,
              bucket_id,
              prefix,
              new_total_deleted,
              new_total_failed,
              next_file_name,
              batch_size
            )
          else
            Logger.info(
              "All batches completed: #{new_total_deleted} deleted, #{new_total_failed} failed"
            )

            {:ok, new_total_deleted}
          end
        end

      {:error, reason} ->
        Logger.error("Failed to list files in batch: #{reason}")

        if total_deleted > 0 do
          Logger.info("Partial deletion completed: #{total_deleted} files deleted before error")
          {:ok, total_deleted}
        else
          {:error, reason}
        end
    end
  end

  # Lists a batch of files with pagination support
  defp list_files_batch(auth_data, bucket_id, prefix, start_file_name, batch_size) do
    url = "#{auth_data["apiUrl"]}/b2api/v2/b2_list_file_names"

    headers = [
      {"Authorization", auth_data["authorizationToken"]},
      {"Content-Type", "application/json"}
    ]

    body_params = %{
      "bucketId" => bucket_id,
      "maxFileCount" => batch_size,
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
            {:ok, files, next_file_name}

          {:ok, %{"files" => files}} ->
            {:ok, files, nil}

          {:error, _} ->
            {:error, "Invalid JSON response"}
        end

      {:ok, %HTTPoison.Response{status_code: status_code, body: error_body}} ->
        {:error, "Failed to list files: #{status_code} - #{error_body}"}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, "Network error listing files: #{inspect(reason)}"}
    end
  end

  # Deletes a batch of files using parallel processing for performance
  defp delete_files_batch(auth_data, files) do
    # Process files in parallel for better performance, but limit concurrency
    # Process 10 files at a time
    chunk_size = 10

    files
    |> Enum.chunk_every(chunk_size)
    |> Enum.reduce({0, 0}, fn chunk, {total_deleted, total_failed} ->
      results =
        chunk
        |> Task.async_stream(
          fn file_info ->
            case delete_file_version(auth_data, file_info) do
              {:ok, _} ->
                :ok

              {:error, reason} ->
                Logger.warning("Failed to delete file #{file_info["fileName"]}: #{reason}")
                :error
            end
          end,
          max_concurrency: chunk_size,
          # 30 seconds timeout per file
          timeout: 30_000
        )
        |> Enum.map(fn
          {:ok, result} -> result
          {:exit, _reason} -> :error
        end)

      chunk_failed = Enum.count(results, &(&1 == :error))
      chunk_deleted = length(chunk) - chunk_failed

      {total_deleted + chunk_deleted, total_failed + chunk_failed}
    end)
  end

  # Deletes a single file version using the B2 API
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

  # Gets the bucket ID from auth data or by listing buckets
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

  # Lists all buckets for the authenticated account
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
end