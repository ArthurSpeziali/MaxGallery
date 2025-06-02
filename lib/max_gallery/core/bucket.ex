defmodule MaxGallery.Core.Bucket do
    alias Mongo.GridFs.Bucket
    alias Mongo.GridFs.Upload
    alias Mongo.GridFs.Download
    @bucket "gridfs"
    @temp "/tmp/max_gallery/temp/"


    defp mongo_pid() do
        Ecto.Adapter.lookup_meta(MaxGallery.Repo)
        |> Map.fetch!(:pid)
    end

    defp get_id(stream) do
        stream.id.value
        |> Base.encode16(case: :lower)
    end

    
    def new_bucket(name) do
        Bucket.new(
            mongo_pid(),
            name: name
        )
    end

    def drop() do
        bucket = new_bucket(@bucket)
        Bucket.drop(bucket)
    end


    def write(content) do
        file = "#{Enum.random(1..10_000//1)}.upload"
        path = @temp <> file

        File.mkdir_p!(@temp)
        File.write(path, content, [:write])

        path
    end


    def upload(path, name) do
        bucket = new_bucket(@bucket)
        upload = Upload.open_upload_stream(bucket, name)

        File.stream!(path, [], 512)
        |> Stream.into(upload)
        |> Stream.run()

        {:ok, get_id(upload)}
    end

    def download(id) do
        bucket = new_bucket(@bucket)
        {:ok, stream} = Download.open_download_stream(bucket, id)

        {:ok, 
            Enum.reduce(stream, <<>>, &(&2 <> &1))
        }
    end
    def download(dest, id) do
        bucket = new_bucket(@bucket)
        {:ok, stream} = Download.open_download_stream(bucket, id)

        Stream.into(
            stream,
            File.stream!(dest)
        ) |> Stream.run()

        :ok
    end

    def replace(id, content) do
        file = write(content)

        bucket = new_bucket(@bucket)
        Bucket.delete(bucket, id)

        upload(file, Path.basename(file))
    end

    def delete(id) do
        bucket = new_bucket(@bucket)
        {:ok, result} = Bucket.delete(bucket, id)

        {:ok, result.deleted_count}
    end

end
