defmodule MaxGallery.Core.Group.Api do
  import Ecto.Query
  alias MaxGallery.Core.Group
  alias MaxGallery.Repo

  def get_own(id) do
    from(Group)
    |> where(id: ^id)
    |> select([g], g.user_id)
    |> Repo.one()
    |> case do
      nil -> {:error, "not found"}
      querry -> {:ok, querry}
    end
  end

  ## Get all groups who are children. It's not recursive.
  def all_group(user, group_id) do
    querry =
      case group_id do
        nil ->
          from(g in Group, where: is_nil(g.group_id))

        id ->
          from(g in Group, where: g.group_id == ^id)
      end
      |> where(user_id: ^user)
      |> Repo.all()

    {:ok, querry}
  end

  def all(user) do
    querry = 
      from(Group)
      |> where(user_id: ^user)
      |> Repo.all()

    {:ok, querry}
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

  def get_timestamps(id) do
    from(g in Group, select: map(g, [:inserted_at, :updated_at]), where: g.id == ^id)
    |> Repo.one()
    |> case do
      nil -> {:error, "not found"}
      querry -> {:ok, querry}
    end
  end

  def delete_all(user) do
    from(Group)
    |> where(user_id: ^user)
    |> Repo.delete_all()
  end
end
