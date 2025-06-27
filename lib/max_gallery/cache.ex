defmodule MaxGallery.Cache do
    alias MaxGallery.Core.Chunk.Api, as: ChunkApi
    alias MaxGallery.Repo


    @spec byte_part() :: pos_integer()
    def byte_part() do
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


    @spec write_chunk(id :: non_neg_integer(), path :: Path.t()) :: any()
    def write_chunk(id, path) do
        File.open!(path, [:write], fn file ->
            Repo.transaction(fn ->
                ChunkApi.from_all_cypher(id)
                |> Repo.stream()
                |> Stream.each(fn blob ->
                    IO.binwrite(file, blob)
                end) |> Stream.run()
            end)
        end)

        :ok
    end

    def get_chunk(id) do
        Repo.transaction(fn ->
            ChunkApi.from_all_cypher(id)
            |> Repo.stream()
            |> Enum.reduce(<<>>, fn blob, acc ->
                acc <> blob
            end)
        end)     
    end

end
