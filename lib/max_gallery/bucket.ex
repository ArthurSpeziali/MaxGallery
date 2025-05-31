defmodule MaxGallery.Bucket do
    alias Mongo.GridFs.Bucket
    alias Mongo.GridFs.Upload
    alias Mongo.GridFs.Download
    @bucket "gridfs"


    defp mongo_pid() do
        Ecto.Adapter.lookup_meta(MaxGallery.Repo)
        |> Map.fetch!(:pid)
    end

    defp get_id(stream) do
        stream.id.value
        |> Base.encode16(case: :lower)
    end

    
    def new_bucket(name, opts \\ []) do
        Bucket.new(
            mongo_pid(),
            [name: name] ++ opts
        )
    end


    def upload(path, name) do
        bucket = new_bucket(@bucket)
        upload = Upload.open_upload_stream(bucket, name)

        File.stream!(path, [], 512)
        |> Stream.into(upload)
        |> Stream.run()

        get_id(upload)
    end

    def download(dest, id) do
        bucket = new_bucket(@bucket)
        {:ok, stream} = Download.open_download_stream(bucket, id)

        Stream.into(
            stream,
            File.stream!(dest)
        ) |> Stream.run()
    end

end
