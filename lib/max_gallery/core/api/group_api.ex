defmodule MaxGallery.Core.Group.Api do
  import Ecto.Query
  alias MaxGallery.Core.Group
  alias MaxGallery.Core.User.Api, as: UserApi
  alias MaxGallery.Repo

  defp swap_id({:ok, querry}) do
    {:ok, swap_id(querry)}
  end

  defp swap_id(querry) when is_list(querry) do
    Enum.map(querry, &swap_id/1)
  end

  defp swap_id(querry) when is_map(querry) do
    case Map.get(querry, :file) do
      nil -> querry
      file_value -> 
        # Convert group_id from internal to public ID if it exists
        updated_querry = if Map.get(querry, :group_id) do
          case get_public_group_id(querry.user_id, querry.group_id) do
            {:ok, public_group_id} -> Map.put(querry, :group, public_group_id)
            {:error, _} -> Map.put(querry, :group, querry.group_id)
          end
        else
          Map.put(querry, :group, nil)
        end
        
        updated_querry
        |> Map.put(:id, file_value)
        |> Map.delete(:file)
    end
  end
  
  # Helper function to convert public ID (file field) to internal ID
  defp get_internal_group(user, public_id) do
    from(Group)
    |> where(user_id: ^user)
    |> where(file: ^public_id)
    |> select([g], g.id)
    |> Repo.one()
    |> case do
      nil -> {:error, "not found"}
      internal_id -> {:ok, internal_id}
    end
  end
  
  # Helper function to get group by internal ID and return with public ID
  def get_by_internal_id(user, internal_id) do
    from(Group)
    |> where(user_id: ^user)
    |> where(id: ^internal_id)
    |> Repo.one()
    |> case do
      nil -> {:error, "not found"}
      querry -> {:ok, swap_id(querry)}
    end
  end
  
  # Helper function to get internal ID from public ID
  def get_internal_id_by_public(user, public_id) do
    get_internal_group(user, public_id)
  end
  
  # Helper function to convert internal group ID to public ID
  defp get_public_group_id(user, internal_id) do
    from(Group)
    |> where(user_id: ^user)
    |> where(id: ^internal_id)
    |> select([g], g.file)
    |> Repo.one()
    |> case do
      nil -> {:error, "not found"}
      public_id -> {:ok, public_id}
    end
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
          # Convert public ID to internal ID for querry
          case get_internal_group(user, id) do
            {:ok, internal_id} ->
              from(g in Group, where: g.group_id == ^internal_id)
            {:error, _} ->
              # If conversion fails, return empty querry
              from(g in Group, where: false)
          end
      end
      |> where(user_id: ^user)
      |> Repo.all()

    {:ok, swap_id(querry)}
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
    
    # Convert public group_id to internal id if provided
    params = if params[:group_id] do
      case get_internal_group(user, params[:group_id]) do
        {:ok, internal_id} -> Map.put(params, :group_id, internal_id)
        {:error, _} -> params  # Keep original if conversion fails
      end
    else
      params
    end

    struct(%Group{}, params)
    |> Repo.insert()
    |> swap_id()
  end

  def get(user, id) do
    querry = from(Group)
    |> where(user_id: ^user)
    
    querry = 
      if id do
        where(querry, file: ^id)
      else
        where(querry, [g], is_nil(g.file))
      end

    querry
    |> Repo.one()
    |> case do
      nil -> {:error, "not found"}
      querry -> {:ok, swap_id(querry)}
    end
  end

  def delete(user, id) do
    # Get the record using the internal querry without swap_id
    querry = from(Group)
    |> where(user_id: ^user)
    
    querry = if id do
      where(querry, file: ^id)
    else
      where(querry, [g], is_nil(g.file))
    end
    
    case Repo.one(querry) do
      nil -> {:error, "not found"}
      querry -> Repo.delete(querry) |> swap_id()
    end
  end

  def update(user, id, params) do
    # Convert public group_id to internal id if provided
    params = if params[:group_id] do
      case get_internal_group(user, params[:group_id]) do
        {:ok, internal_id} -> Map.put(params, :group_id, internal_id)
        {:error, _} -> params  # Keep original if conversion fails
      end
    else
      params
    end
    
    # Get the record using the internal querry without swap_id
    querry = from(Group)
    |> where(user_id: ^user)
    
    querry = if id do
      where(querry, file: ^id)
    else
      where(querry, [g], is_nil(g.file))
    end
    
    case Repo.one(querry) do
      nil -> {:error, "not found"}
      querry ->
        changeset = Group.changeset(querry, params)
        case Repo.update(changeset) do
          {:ok, new_querry} -> {:ok, swap_id(new_querry)}
          error -> error
        end
    end
  end

  def get_timestamps(user, id) do
    querry = from(Group)
    |> where(user_id: ^user)
    |> select([c], map(c, [:inserted_at, :updated_at]))
    
    querry = if id do
      where(querry, file: ^id)
    else
      where(querry, [g], is_nil(g.file))
    end
    
    querry
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
