defmodule MaxGallery.Cache do
    alias MaxGallery.Core.Chunk.Api, as: ChunkApi
    alias MaxGallery.Repo
    alias MaxGallery.Phantom
    alias MaxGallery.Encrypter
    @tmp_path "/tmp/max_gallery/cache/"


    @spec chunk_size() :: pos_integer()
    def chunk_size() do
        32 * 1024 ## 32KB
    end

    @spec insert_chunk(list(), index :: non_neg_integer(), params :: map()) :: :ok
    def insert_chunk(list, index \\ 0, params)
    def insert_chunk([], _index, _params), do: :ok
    def insert_chunk([head | tail], index, params) do
        Map.merge(
            %{blob: head, index: index},
            params
        ) |> ChunkApi.insert()

        insert_chunk(tail, index + 1, params)
    end

    @spec write_chunk(id :: pos_integer(), blob_iv :: binary()) :: Path.t()
    def write_chunk(id, blob_iv) do
        folder_path = "/tmp/max_gallery/cache/"
        file_path = folder_path <> "#{id}_encode"
        File.mkdir_p!(folder_path)


        {:ok, enc_blob} = get_chunk(id)
        {:ok, blob} = Encrypter.decrypt(
            {blob_iv, enc_blob},
            "key"
        )

        File.write!(
            file_path,
            Phantom.validate_bin(blob),
            [:write]
        )
    end

    @spec get_chunk(id :: pos_integer()) :: binary()
    def get_chunk(id) do
        Repo.transaction(fn ->
            ChunkApi.from_all_cypher(id)
            |> Repo.stream()
            |> Enum.reduce(<<>>, fn blob, acc ->
                acc <> blob
            end)
        end)     
    end

    @spec encode_chunk(path :: Path.t()) :: Path.t()
    def encode_chunk(path) do
        File.open!(path <> "_encode", [:write], fn output ->
            File.stream!(path, [], chunk_size())
            |> Stream.each(fn chunk ->
                encoded_data = Phantom.validate_bin(chunk)
                IO.binwrite(output, encoded_data)
            end) |> Stream.run()
        end)

        File.rm!(path)
        path <> "_encode"
    end

    @spec consume_cache(id :: pos_integer(), blob_iv :: binary()) :: {:ok, boolean()}
    def consume_cache(id, blob_iv) do
        path = @tmp_path <> "#{id}_encode"

        if File.exists?(path) do
            {path, false}
        else
            write_chunk(id, blob_iv)
            {path, true}
        end|> IO.inspect()
    end
end
