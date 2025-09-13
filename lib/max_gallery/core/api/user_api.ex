defmodule MaxGallery.Core.User.Api do
  import Ecto.Query, except: [update: 2]
  alias MaxGallery.Core.User
  alias MaxGallery.Repo

  def serial(user) do
    from(User)
    |> where(id: ^user)
    |> select([u], u.last_file)
    
    |> Repo.one()
    |> case do
      nil -> {:error, "not found"}
      serial -> 
        update(user, %{last_file: serial + 1})
        {:ok, serial}
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
