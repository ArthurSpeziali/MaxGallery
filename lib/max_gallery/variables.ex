defmodule MaxGallery.Variables do
  ## 1MB
  @chunk_size 1 * 1024 * 1024
  @tmp_dir "/tmp/max_gallery/"
  ## 100 MB (1e⁸)
  @file_size 1 * 10 ** 8
  @email_subject "Max Gallery"
  @file_limit 64
  ## 90 Days! (In seconds)
  @cookie_time 90 * 24 * 60 * 60
  @code_digits 6
  # In minutes (3 Hours)
  @reset_time 3 * 60
  # In seconds (2 minutes)
  @email_resend 2 * 60
  # 12 hours (in miliseconds)
  @delete_reqs 12 * 60 * 60 * 1000
  @gen_clound "encrypted_files"
  @bucket_name "maxgallery-files"
  @max_objects 25_000
  ## 5GB per user limit
  @max_size_user 3.0

  def chunk_size, do: @chunk_size
  def tmp_dir, do: @tmp_dir
  def file_size, do: @file_size
  def email_subject, do: @email_subject
  def file_limit, do: @file_limit
  def cookie_time, do: @cookie_time
  def code_digits, do: @code_digits
  def reset_time, do: @reset_time
  def email_resend, do: @email_resend
  def delete_reqs, do: @delete_reqs
  def bucket_name, do: @bucket_name
  def gen_clound, do: @gen_clound
  def max_objects, do: @max_objects
  def max_size_user, do: @max_size_user
end
