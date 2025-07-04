defmodule MaxGallery.Core.Bucket do
    alias Mongo.GridFs.Bucket
    alias Mongo.GridFs.Upload
    alias Mongo.GridFs.Download
    @bucket "gridfs"
    @temp "/tmp/max_gallery/temp/"


    @spec mongo_pid() :: pid()
    defp mongo_pid() do
        ## Extract the Mongo operation pid, from Ecto (Using mongodb_driver).
        Ecto.Adapter.lookup_meta(MaxGallery.Repo)
        |> Map.fetch!(:pid)
    end


    @spec get_id(stream :: struct()) :: String.t()
    defp get_id(stream) do
        ## Get the id from a Mongo Stream, Kind of useless.
        stream.id.value
        |> Base.encode16(case: :lower)
    end


    @spec get_bucket() :: struct()
    def get_bucket() do
        ## If the bucket dows not exists, create new.
        Bucket.new(
            mongo_pid(),
            name: @bucket
        )
    end

    @spec drop() :: :ok
    def drop() do
        bucket = get_bucket()
        Bucket.drop(bucket)
    end


    @spec write(content :: binary()) :: Path.t()
    def write(content) do
        file = "#{Enum.random(1..10_000//1)}.upload"
        path = @temp <> file

        File.mkdir_p!(@temp)
        File.write(path, content, [:write])

        path
    end


    @spec upload(path :: Path.t(), name :: String.t()) :: {:ok, String.t()}
    def upload(path, name) do
        bucket = get_bucket()
        upload = Upload.open_upload_stream(bucket, name)

        File.stream!(path, [], 512)
        |> Stream.into(upload)
        |> Stream.run()

        {:ok, get_id(upload)}
    end

    @spec download(id :: binary()) :: {:ok, Stream.acc()}
    def download(id) do
        bucket = get_bucket()
        {:ok, stream} = Download.open_download_stream(bucket, id)

        {:ok, 
            Enum.reduce(stream, <<>>, &(&2 <> &1))
        }
    end
    @spec download(dest :: Path.t(), id :: binary()) :: :ok
    def download(dest, id) do
        bucket = get_bucket()
        {:ok, stream} = Download.open_download_stream(bucket, id)

        Stream.into(
            stream,
            File.stream!(dest)
        ) |> Stream.run()

        :ok
    end

    @spec replace(id :: binary(), content :: binary()) :: {:ok, String.t()}
    def replace(id, content) do
        file = write(content)

        bucket = get_bucket()
        Bucket.delete(bucket, id)

        upload(file, Path.basename(file))
    end

    @spec delete(id :: binary()) :: {:ok, non_neg_integer()}
    def delete(id) do
        bucket = get_bucket()
        {:ok, result} = Bucket.delete(bucket, id)

        {:ok, result.deleted_count}
    end

    @spec get(id :: binary()) :: {:ok, struct()}
    def get(id) do
        ## Get only the file metadata.
        bucket = get_bucket()

        {:ok, 
            Bucket.find_one(bucket, id)
        }
    end

end
