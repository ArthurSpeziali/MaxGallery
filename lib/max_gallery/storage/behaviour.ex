defmodule MaxGallery.Storage.Behaviour do
  @moduledoc """
  Behaviour for storage implementations.
  This allows us to swap between real S3 storage and mock storage for testing.
  """

  @callback put(binary(), binary()) :: {:ok, String.t()} | {:error, String.t()}
  @callback get(binary()) :: {:ok, binary()} | {:error, String.t()}
  @callback del(binary()) :: :ok | {:error, String.t()}
  @callback del_all() :: {:ok, integer()} | {:error, String.t()}
  @callback exists?(binary()) :: boolean()
  @callback list() :: {:ok, list(map())} | {:error, String.t()}
end