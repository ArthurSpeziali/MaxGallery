defmodule MaxGallery.Core.Data.Api do
    import Ecto.Query, only: [from: 2, first: 1]
    alias MaxGallery.Core.Data
    alias MaxGallery.Repo

    def all_group(group_id) do
        querry = 
            case group_id do
                nil ->
                    from(d in Data, where: is_nil(d.group_id))

                id -> 
                    from(d in Data, where: d.group_id == ^id)

            end |> Repo.all()

        case querry do
            _datas when is_list(querry) -> {:ok, querry}
            error -> error
        end
    end

    def all_group_lazy(group_id) do
        fields = Data.fields()
                 |> List.delete(:blob_iv)
                 |> List.delete(:blob)

        querry = 
            case group_id do
                nil ->
                    from(d in Data, select: map(d, ^fields), where: is_nil(d.group_id))

                id -> 
                    from(d in Data, select: map(d, ^fields), where: d.group_id == ^id)

            end |> Repo.all()

        case querry do
            _data when is_list(querry) -> {:ok, querry}
            error -> error
        end
    end


    def all() do
        Repo.all(Data)
        |> case do
            data when is_list(data) -> {:ok, data}
            error -> error
        end
    end

    def all_lazy() do
        fields = Data.fields()
                 |> List.delete(:blob)
                 |> List.delete(:blob_iv)

        from(d in Data, select: map(d, ^fields))
        |> Repo.all()
        |> case do
            data when is_list(data) -> {:ok, data}
            error -> error
        end
    end

    def get_lazy(id) do
        fields = Data.fields()
                 |> List.delete(:blob)
                 |> List.delete(:blob_iv)

        from(d in Data, select: map(d, ^fields))
        |> Repo.get(id)
        |> case do
            nil -> {:error, nil}
            querry -> {:ok, querry}
        end
    end

    def first_lazy() do
        fields = Data.fields()
                 |> List.delete(:blob)
                 |> List.delete(:blob_iv)

        from(d in Data, select: map(d, ^fields))
        |> first()
        |> Repo.one()
        |> case do
            nil -> {:error, nil}
            querry -> {:ok, querry}
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


    def get_size(id) do
        from(d in Data, select: fragment("LENGTH(?) + LENGTH(?)", d.blob, d.blob_iv), where: d.id == ^id)
        |> Repo.one()
        |> case do
            nil -> {:error, "not found"}
            querry -> {:ok, querry}
        end
    end


    def get_timestamps(id) do
        from(d in Data, select: map(d, [:inserted_at, :updated_at]), where: d.id == ^id)
        |> Repo.one()
        |> case do
            nil -> {:error, "not found"}
            querry -> {:ok, querry}
        end
    end
end
