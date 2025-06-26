defmodule MaxGallery.Core.Data.Api do
    import Ecto.Query, only: [from: 2, first: 1]
    alias MaxGallery.Core.Data
    alias MaxGallery.Repo


    ## Get all datas who are children. It's not recursive.
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


    def all() do
        Repo.all(Data)
        |> case do
            data when is_list(data) -> {:ok, data}
            error -> error
        end
    end


    def first() do
        fields = Data.fields()

        from(d in Data, select: map(d, ^fields))
        |> first()
        |> Repo.one()
        |> case do
            nil -> {:error, "not found"}
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


    def get_length(id) do
        from(d in Data, select: %{length: fragment("octet_length(?)", d.blob)}, where: d.id == ^id)
        |> Repo.one()

        |> case do
            %{length: length} -> {:ok, length}
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

    def delete_all() do
        Repo.delete_all(Data)
    end


end
