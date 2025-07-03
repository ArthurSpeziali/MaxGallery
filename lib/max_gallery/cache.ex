defmodule MaxGallery.Cache do
    alias MaxGallery.Core.Chunk.Api, as: ChunkApi
    alias MaxGallery.Repo
    alias MaxGallery.Phantom
    alias MaxGallery.Utils
    alias MaxGallery.Encrypter
    alias MaxGallery.Variables
    @tmp_path Variables.tmp_dir <> "cache/"


    @spec insert_chunk(list :: list(), params :: map(), index :: non_neg_integer()) :: :ok
    def insert_chunk(list, params, index \\ 0)
    def insert_chunk([], _params, _index), do: :ok
    def insert_chunk([head | tail], params, index) do
        Map.merge(
            params,
            %{blob: head, index: index}
        ) |> ChunkApi.insert()

        insert_chunk(tail, params, index + 1)
    end

    @spec write_chunk(id :: pos_integer(), blob_iv :: binary()) :: Path.t()
    def write_chunk(id, blob_iv) do
        file_path = @tmp_path <> "#{Mix.env()}_#{id}"
        File.mkdir_p!(@tmp_path)


        {:ok, enc_blob} = get_chunks(id)
        {:ok, blob} = Encrypter.decrypt(
            {blob_iv, enc_blob},
            "key"
        )

        File.write!(
            file_path,
            blob,
            [:write]
        )
    end

    @spec get_chunks(id :: pos_integer()) :: binary()
    def get_chunks(id) do
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
            File.stream!(path, [], Variables.chunk_size)
            |> Stream.each(fn chunk ->
                encoded_data = Phantom.validate_bin(chunk)
                IO.binwrite(output, encoded_data)
            end) |> Stream.run()
        end)

        File.rm!(path)
        inspect(Mix.env) <> "_" <> path <> "_encode"
    end

    @spec consume_cache(id :: pos_integer(), blob_iv :: binary()) :: {:ok, boolean()}
    def consume_cache(id, blob_iv) do
        path = @tmp_path <> "#{Mix.env}_#{id}"

        if File.exists?(path) do
            {path, false}
        else
            write_chunk(id, blob_iv)
            {path, true}
        end
    end

    @spec get_length(id :: pos_integer()) :: {:ok, integer()}
    def get_length(id) do
        ChunkApi.first_length(id)
        |> Repo.one()
        |> case do
            querry -> {:ok, querry}
        end
    end

    @spec update_chunks(id :: pos_integer(), blob :: binary()) :: :ok
    def update_chunks(id, blob) do
        ChunkApi.delete_cypher(id)

        Utils.binary_chunk(blob, Variables.chunk_size)
        |> insert_chunk(%{
            length: byte_size(blob),
            cypher_id: id
        })
    end
end
