defmodule MaxGallery.Variables do
    @chunk_size 1 * 1024 * 1024 ## 1MB
    @tmp_dir "/tmp/max_gallery/"
    @file_size 2 * 10 ** 9 ## 2GB


    def chunk_size, do: @chunk_size
    def tmp_dir, do: @tmp_dir
    def file_size, do: @file_size
end
