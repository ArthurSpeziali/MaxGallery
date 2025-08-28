defmodule MaxGallery.Storage.Behaviour do
  @moduledoc """
  Behaviour for storage implementations.
  This allows us to swap between real S3 storage and mock storage for testing.
  """

  @callback put(user :: binary(), id :: binary(), blob :: binary()) :: {:ok, String.t()} | {:error, String.t()}
  @callback get(user :: binary(), id :: binary()) :: {:ok, binary()} | {:error, String.t()}
  @callback del(user :: binary(), id :: binary()) :: :ok | {:error, String.t()}
  @callback del_all(user :: binary()) :: {:ok, integer()} | {:error, String.t()}
  @callback exists?(user :: binary(), id :: binary()) :: boolean()
  @callback list(user :: binary()) :: {:ok, list(map())} | {:error, String.t()}
end