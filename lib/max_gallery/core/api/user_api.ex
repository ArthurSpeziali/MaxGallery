defmodule MaxGallery.Core.User.Api do
  import Ecto.Query, except: [update: 2]
  alias MaxGallery.Core.User
  alias MaxGallery.Repo

  def serial(user) do
    # Use a database transaction to ensure atomicity
    Repo.transaction(fn ->
      # Lock the user row for update to prevent race conditions
      query = from(u in User,
        where: u.id == ^user,
        lock: "FOR UPDATE"
      )
      
      case Repo.one(query) do
        nil -> 
          Repo.rollback("not found")
        user_record -> 
          current_serial = user_record.last_file
          
          # Update the last_file atomically
          changeset = User.changeset(user_record, %{last_file: current_serial + 1})
          case Repo.update(changeset) do
            {:ok, _updated} -> current_serial
            {:error, reason} -> Repo.rollback(reason)
          end
      end
    end)
    |> case do
      {:ok, serial} -> {:ok, serial}
      {:error, reason} -> {:error, reason}
    end
  end



  def exists(user) do
    case Ecto.UUID.cast(user) do
      {:ok, _user} ->
        from(User)
        |> where(id: ^user)
        |> Repo.one()
        |> case do
          nil -> {:error, "not found"}
          querry -> {:ok, querry}
        end

      :error ->
        {:error, "invalid uuid"}
    end
  end

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

  def get(user) do
    Repo.get(User, user)
    |> case do
      nil -> {:error, "not found"}
      querry -> {:ok, querry}
    end
  end

  def delete(user) do
    case get(user) do
      {:ok, querry} -> Repo.delete(querry)
      error -> error
    end
  end

  def update(user, params) do
    with {:ok, querry} <- get(user),
         changeset <- User.changeset(querry, params),
         {:ok, new_querry} <- Repo.update(changeset) do
      {:ok, new_querry}
    else
      error -> error
    end
  end
end
