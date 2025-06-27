defmodule MaxGallery.Core.Chunk.Api do
    alias MaxGallery.Core.Chunk
    alias MaxGallery.Repo
    import Ecto.Query


    def first_length(id) do
        from(Chunk)
        |> where(cypher_id: ^id)
        |> first()
        |> select([c], c.length)
    end

    def from_all_cypher(id) do
        from(Chunk)
        |> where(cypher_id: ^id)
        |> order_by(asc: :index)
        |> select([c], c.blob)
    end

    def all() do
        Repo.all(Chunk)
        |> case do
            querry -> {:ok, querry}
        end
    end

    def get(id) do
        Repo.get(Chunk, id) 
        |> case do
            nil -> {:error, "not found"}
            querry -> {:ok, querry}
        end
    end

    def delete(id) do
        case get(id) do
            {:ok, querry} -> Repo.delete(querry)
            error -> error
        end
    end

    def update(id, params) do
        with {:ok, querry} <- get(id),
             changeset <- Chunk.changeset(querry, params),
             {:ok, new_querry} <- Repo.update(changeset) do

            {:ok, new_querry}
        else
            error -> error
        end
    end

    def insert(params) do
        struct(%Chunk{}, params)
        |> Repo.insert()
    end

    def delete_cypher(id) do
        from(Chunk)
        |> where(cypher_id: ^id)
        |> Repo.delete_all()
    end

end
