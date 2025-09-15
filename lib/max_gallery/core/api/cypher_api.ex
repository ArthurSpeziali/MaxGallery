defmodule MaxGallery.Core.Cypher.Api do
  import Ecto.Query
  alias MaxGallery.Core.Cypher
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
  
  # Helper function to convert public group ID to internal ID
  defp get_internal_group(user, public_id) do
    alias MaxGallery.Core.Group
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
  
  # Helper function to convert internal group ID to public ID
  defp get_public_group_id(user, internal_id) do
    alias MaxGallery.Core.Group
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

  def all_size(user) do
    from(Cypher)
    |> where(user_id: ^user)
    |> select([c], c.length)
    |> Repo.all()
    |> case do
      querry -> {:ok, querry}
    end
  end

  # def get_own(id) do
  #   from(Cypher)
  #   |> where(file: ^id)
  #   |> select([c], c.user_id)
  #   |> Repo.one()
  #   |> case do
  #     nil -> {:error, "not found"}
  #     querry -> {:ok, swap_id(querry)}
  #   end
  # end

  def get_length(user, id) do
    query = from(Cypher)
    |> where(user_id: ^user)
    |> select([c], c.length)
    
    query = if id do
      where(query, file: ^id)
    else
      where(query, [c], is_nil(c.file))
    end
    
    query
    |> Repo.one()
    |> case do
      nil -> {:error, "not found"}
      querry -> {:ok, querry}
    end
  end

  ## Get all datas who are children. It's not recursive.
  def all_group(user, group_id) do
    querry =
      case group_id do
        nil ->
          from(d in Cypher, where: is_nil(d.group_id))

        id ->
          # Convert public group ID to internal ID for query
          case get_internal_group(user, id) do
            {:ok, internal_id} ->
              from(d in Cypher, where: d.group_id == ^internal_id)
            {:error, _} ->
              # If conversion fails, return empty query
              from(d in Cypher, where: false)
          end
      end
      |> where(user_id: ^user)
      |> Repo.all()

    {:ok, swap_id(querry)}
  end

  def all(user) do
    from(Cypher)
    |> where(user_id: ^user)
    |> Repo.all()
    |> case do
      querry -> {:ok, swap_id(querry)}
    end
  end

  def first_one(user) do
    fields = Cypher.fields()

    from(d in Cypher, select: map(d, ^fields))
    |> where(user_id: ^user)
    |> first()
    |> Repo.one()
    |> case do
      nil -> {:error, "not found"}
      querry -> {:ok, swap_id(querry)}
    end
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

    struct(%Cypher{}, params)
    |> Repo.insert()
    |> swap_id()
  end

  def get(user, id) do
    query = from(Cypher)
    |> where(user_id: ^user)
    
    query = if id do
      where(query, file: ^id)
    else
      where(query, [c], is_nil(c.file))
    end
    
    query
    |> Repo.one()
    |> case do
      nil -> {:error, "not found"}
      querry -> {:ok, swap_id(querry)}
    end
  end

  def delete(user, id) do
    # Get the record using the internal query without swap_id
    query = from(Cypher)
    |> where(user_id: ^user)
    
    query = if id do
      where(query, file: ^id)
    else
      where(query, [c], is_nil(c.file))
    end
    
    case Repo.one(query) do
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
    
    # Get the record using the internal query without swap_id
    query = from(Cypher)
    |> where(user_id: ^user)
    
    query = if id do
      where(query, file: ^id)
    else
      where(query, [c], is_nil(c.file))
    end
    
    case Repo.one(query) do
      nil -> {:error, "not found"}
      querry ->
        changeset = Cypher.changeset(querry, params)
        case Repo.update(changeset) do
          {:ok, new_querry} -> {:ok, swap_id(new_querry)}
          error -> error
        end
    end
  end

  def get_timestamps(user, id) do
    query = from(Cypher)
    |> where(user_id: ^user)
    |> select([c], map(c, [:inserted_at, :updated_at]))
    
    query = if id do
      where(query, file: ^id)
    else
      where(query, [c], is_nil(c.file))
    end
    
    query
    |> Repo.one()
    |> case do
      nil -> {:error, "not found"}
      querry -> {:ok, querry} # Doesn't  need  swap_id/1
    end
  end

  def delete_all(user) do
    from(Cypher)
    |> where(user_id: ^user)
    |> Repo.delete_all()
  end
end
