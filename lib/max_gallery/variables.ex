defmodule MaxGallery.Variables do
  ## 1MB
  @chunk_size 1 * 1024 * 1024
  @tmp_dir "/tmp/max_gallery/"
  ## 2GB
  @file_size 2 * 10 ** 9
  @email_subject "Max Gallery"
  @email_user "os.maxgallery@gmail.com"
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
  @max_objects 25_000

  def chunk_size, do: @chunk_size
  def tmp_dir, do: @tmp_dir
  def file_size, do: @file_size
  def email_user, do: @email_user
  def email_subject, do: @email_subject
  def file_limit, do: @file_limit
  def cookie_time, do: @cookie_time
  def code_digits, do: @code_digits
  def reset_time, do: @reset_time
  def email_resend, do: @email_resend
  def delete_reqs, do: @delete_reqs
  def bucket_name, do: System.get_env("BLACKBLAZE_BUCKET_NAME", "maxgallery-files")
  def gen_clound, do: @gen_clound
  def max_objects, do: @max_objects
end
