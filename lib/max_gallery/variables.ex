defmodule MaxGallery.Variables do
  @moduledoc """
  Centralized configuration constants for the MaxGallery system.

  This module provides compile-time constants for various system limits,
  timeouts, and configuration values used throughout the application.

  ## Categories

  ### File Processing
  - Chunk sizes for streaming operations
  - File size limits and thresholds
  - Temporary directory paths

  ### User Limits
  - Storage quotas per user
  - File count limitations
  - Object count restrictions

  ### Security & Authentication
  - Cookie expiration times
  - Code generation parameters
  - Wait times for rate limiting

  ### Email Configuration
  - Subject line templates
  - Resend intervals
  - Verification timeouts

  ### Storage Configuration
  - Bucket names for cloud storage
  - Streaming thresholds
  - Cleanup intervals

  All values are compile-time constants for optimal performance.
  """

  ## 1MB
  @chunk_size 5 * 1024 * 1024
  @tmp_dir "/tmp/max_gallery/"
  ## 200 MB (2e⁸)
  @file_size 2 * 10 ** 8
  @email_subject "Max Gallery"
  @file_limit 64
  ## 90 Days! (In seconds)
  @cookie_time 90 * 24 * 60 * 60
  @code_digits 6
  # In Seconds (3 minutes)
  @wait_time 3 * 60
  # In seconds (2 minutes)
  @email_resend 2 * 60
  # 12 hours (in miliseconds)
  @delete_reqs 12 * 60 * 60 * 1000
  @gen_clound "encrypted_files"
  @bucket_name "maxgallery-files"
  @max_objects 25_000
  ## 5GB per user limit
  @max_size_user 3.0

  @doc "Returns the chunk size for file streaming operations (5MB)."
  @spec chunk_size() :: pos_integer()
  def chunk_size, do: @chunk_size

  @doc "Returns the temporary directory path for file operations."
  @spec tmp_dir() :: String.t()
  def tmp_dir, do: @tmp_dir

  @doc "Returns the maximum file size limit (100MB)."
  @spec file_size() :: pos_integer()
  def file_size, do: @file_size

  @doc "Returns the default email subject for system emails."
  @spec email_subject() :: String.t()
  def email_subject, do: @email_subject

  @doc "Returns the maximum number of files per operation."
  @spec file_limit() :: pos_integer()
  def file_limit, do: @file_limit

  @doc "Returns the cookie expiration time in seconds (90 days)."
  @spec cookie_time() :: pos_integer()
  def cookie_time, do: @cookie_time

  @doc "Returns the number of digits for generated verification codes."
  @spec code_digits() :: pos_integer()
  def code_digits, do: @code_digits

  @doc "Returns the wait time for rate limiting in seconds (3 minutes)."
  @spec wait_time() :: pos_integer()
  def wait_time, do: @wait_time

  @doc "Returns the minimum interval between email resends in seconds (2 minutes)."
  @spec email_resend() :: pos_integer()
  def email_resend, do: @email_resend

  @doc "Returns the timeout for delete requests in milliseconds (12 hours)."
  @spec delete_reqs() :: pos_integer()
  def delete_reqs, do: @delete_reqs

  @doc "Returns the cloud storage bucket name."
  @spec bucket_name() :: String.t()
  def bucket_name, do: @bucket_name

  @doc "Returns the generic cloud storage identifier."
  @spec gen_clound() :: String.t()
  def gen_clound, do: @gen_clound

  @doc "Returns the maximum number of objects allowed."
  @spec max_objects() :: pos_integer()
  def max_objects, do: @max_objects

  @doc "Returns the maximum storage size per user in GB."
  @spec max_size_user() :: float()
  def max_size_user, do: @max_size_user

  @doc "Returns the threshold size for using streaming operations (10MB)."
  @spec use_stream() :: pos_integer()
  def use_stream, do: 2 * @chunk_size

end
