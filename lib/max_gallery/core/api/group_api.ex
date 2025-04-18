defmodule MaxGallery.Core.Group.Api do
    alias MaxGallery.Core.Group
    alias MaxGallery.Repo


    def all() do
        Repo.all(Group)
        |> case do
            group when is_list(group) -> {:ok, group}
            error -> error
        end
    end

    def insert(params) do
        struct(%Group{}, params)
        |> Repo.insert()
    end

    def get(id) do
        Repo.get(Group, id)
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
             changeset <- Group.changeset(querry, params),
             {:ok, new_querry} <- Repo.update(changeset) do

            {:ok, new_querry}
        else
            error -> error
        end
    end
end
