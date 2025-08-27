defmodule MaxGallery.StorageAdapter do
  @moduledoc """
  Adapter that delegates to the appropriate storage implementation based on environment.
  """

  def impl do
    Application.get_env(:max_gallery, :storage_impl, MaxGallery.Storage)
  end

  def put(cypher_id, blob), do: impl().put(cypher_id, blob)
  def get(cypher_id), do: impl().get(cypher_id)
  def del(cypher_id \\ nil), do: impl().del(cypher_id)
  def del_all, do: impl().del_all()
  def exists?(cypher_id), do: impl().exists?(cypher_id)
  def list, do: impl().list()
end