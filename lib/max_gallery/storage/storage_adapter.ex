defmodule MaxGallery.StorageAdapter do
  @moduledoc """
  Adapter that delegates to the appropriate storage implementation based on environment.
  Uses mock storage for tests and real S3 storage for production.
  """

  def impl do
    case Mix.env() do
      :test -> MaxGallery.Storage.Mock
      _ -> MaxGallery.Storage
    end
  end

  def put(user, id, blob), do: impl().put(user, id, blob)
  def put_stream(user, id, stream), do: impl().put_stream(user, id, stream)
  def put_stream(user, id, stream, part?), do: impl().put_stream(user, id, stream, part?)
  def get(user, id), do: impl().get(user, id)
  def get_stream(user, id), do: impl().get_stream(user, id)
  def get_stream(user, id, dest), do: impl().get_stream(user, id, dest)
  def del(user, id), do: impl().del(user, id)
  def del_all(user), do: impl().del_all(user)
  def exists?(user, id), do: impl().exists?(user, id)
  def list(user), do: impl().list(user)
end
