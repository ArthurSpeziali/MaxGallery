defmodule MaxGallery.Core.Cypher.Api do
  import Ecto.Query
  alias MaxGallery.Core.Cypher
  alias MaxGallery.Repo

  def get_length(id) do
    from(Cypher)
    |> where(id: ^id)
    |> select([c], c.length)

    |> Repo.one()
    |> case do
      nil -> {:error, "not found"}
      querry -> {:ok, querry}
    end
  end

  ## Get all datas who are children. It's not recursive.
  def all_group(group_id) do
    querry =
      case group_id do
        nil ->
          from(d in Cypher, where: is_nil(d.group_id))

        id ->
          from(d in Cypher, where: d.group_id == ^id)
      end
      |> Repo.all()

    case querry do
      _datas when is_list(querry) -> {:ok, querry}
      error -> error
    end
  end

  def all() do
    Repo.all(Cypher)
    |> case do
      data when is_list(data) -> {:ok, data}
      error -> error
    end
  end

  def first() do
    fields = Cypher.fields()

    from(d in Cypher, select: map(d, ^fields))
    |> first()
    |> Repo.one()
    |> case do
      nil -> {:error, "not found"}
      querry -> {:ok, querry}
    end
  end

  def insert(params) do
    struct(%Cypher{}, params)
    |> Repo.insert()
  end

  def get(id) do
    Repo.get(Cypher, id)
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
         changeset <- Cypher.changeset(querry, params),
         {:ok, new_querry} <- Repo.update(changeset) do
      {:ok, new_querry}
    else
      error -> error
    end
  end

  def get_timestamps(id) do
    from(d in Cypher, select: map(d, [:inserted_at, :updated_at]), where: d.id == ^id)
    |> Repo.one()
    |> case do
      nil -> {:error, "not found"}
      querry -> {:ok, querry}
    end
  end

  def delete_all() do
    Repo.delete_all(Cypher)
  end
end
