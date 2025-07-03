defmodule MaxGallery.Core.User.Api do
    import Ecto.Query
    alias MaxGallery.Core.User
    alias MaxGallery.Repo


    def get_email(email) do
        from(User)
        |> where(email: ^email)
        |> Repo.one()

        |> case do
            nil -> {:error, "not found"}
            querry -> {:ok, querry}
        end
    end

    def all() do
        Repo.all(User)
        |> case do
            querry -> {:ok, querry}
        end
    end

    def insert(params) do
        struct(%User{}, params)
        |> Repo.insert()
    end

    def get(id) do
        Repo.get(User, id)
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
             changeset <- User.changeset(querry, params),
             {:ok, new_querry} <- Repo.update(changeset) do

            {:ok, new_querry}
        else
            error -> error
        end
    end
end
