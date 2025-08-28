defmodule MaxGallery.StorageAdapter do
  @moduledoc """
  Adapter that delegates to the appropriate storage implementation based on environment.
  """

  def impl do
    Application.get_env(:max_gallery, :storage_impl, MaxGallery.Storage)
  end

  def put(user, id, blob), do: impl().put(user, id, blob)
  def get(user, id), do: impl().get(user, id)
  def del(user, id), do: impl().del(user, id)
  def del_all(user), do: impl().del_all(user)
  def exists?(user, id), do: impl().exists?(user, id)
  def list(user), do: impl().list(user)
end