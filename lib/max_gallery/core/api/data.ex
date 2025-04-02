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
        Data.changeset(%Data{}, params)
        |> Repo.insert()
    end

end
