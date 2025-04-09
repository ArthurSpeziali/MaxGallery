defmodule MaxGallery.Core.Data.Api do
    alias MaxGallery.Core.Data
    alias MaxGallery.Repo


    def all() do
        Repo.all(Data)
        |> case do
            data when is_list(data) -> {:ok, data}
            error -> error
        end
    end

    def insert(params) do
        struct(%Data{}, params)
        |> Repo.insert()
    end

    def get(id) do
        Repo.get(Data, id)
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
             changeset <- Data.changeset(querry, params),
             {:ok, new_querry} <- Repo.update(changeset) do

            {:ok, new_querry}
        else
            error -> error
        end
    end
end
