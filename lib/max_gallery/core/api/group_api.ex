defmodule MaxGallery.Core.Group.Api do
  import Ecto.Query
  alias MaxGallery.Core.Group
  alias MaxGallery.Core.User.Api, as: UserApi
  alias MaxGallery.Repo

  defp swap_id({:ok, querry}) do
    {:ok, swap_id(querry)}
  end

  defp swap_id(querry) do
    {value, new_querry} =
      Map.delete(querry, :id)
      |> Map.pop(:file)


    Map.put(new_querry, :id, value)
  end
  # def get_own(id) do
  #   from(Group)
  #   |> where(id: ^id)
  #   |> select([g], g.user_id)
  #   |> Repo.one()
  #   |> case do
  #     nil -> {:error, "not found"}
  #     querry -> {:ok, querry}
  #   end
  # end

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

  def insert(user, params) do
    {:ok, serial} = UserApi.serial(user)
    params = Map.put(params, :file, serial)

    struct(%Group{}, params)
    |> Repo.insert()
    |> swap_id()
  end

  def get(user, id) do
    from(Group)
    |> where(file: ^id)
    |> where(user_id: ^user)
    |> Repo.one()

    |> case do
      nil -> {:error, "not found"}
      querry -> {:ok, swap_id(querry)}
    end
  end

  def delete(user, id) do
    case get(user, id) do
      {:ok, querry} -> Repo.delete(querry) |> swap_id()
      error -> error
    end
  end

  def update(user, id, params) do
    with {:ok, querry} <- get(user, id),
         changeset <- Group.changeset(querry, params),
         {:ok, new_querry} <- Repo.update(changeset) do

      {:ok, swap_id(new_querry)}
    else
      error -> error
    end
  end

  def get_timestamps(user, id) do
    from(Group)
    |> where(user_id: ^user)
    |> where(file: ^id)
    |> select([c], map(c, [:inserted_at, :updated_at]))

    |> Repo.one()
    |> case do
      nil -> {:error, "not found"}
      querry -> {:ok, querry} # Doesn't  need  swap_id/1
    end
  end

  def delete_all(user) do
    from(Group)
    |> where(user_id: ^user)
    |> Repo.delete_all()
  end
end
