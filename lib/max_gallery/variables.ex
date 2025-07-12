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

  def chunk_size, do: @chunk_size
  def tmp_dir, do: @tmp_dir
  def file_size, do: @file_size
  def email_user, do: @email_user
  def email_subject, do: @email_subject
  def file_limit, do: @file_limit
  def cookie_time, do: @cookie_time
  def code_digits, do: @code_digits
end
