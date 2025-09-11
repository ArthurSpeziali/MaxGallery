defmodule MaxGallery.Storage.Behaviour do
  @moduledoc """
  Behaviour for storage implementations.
  This allows us to swap between real S3 storage and mock storage for testing.
  """

  @callback put(user :: binary(), id :: integer(), blob :: binary()) ::
              :ok | {:error, String.t()}
  @callback put_stream(user :: binary(), id :: integer(), stream :: Enum.t()) ::
              :ok | {:error, String.t()}
  @callback put_stream(user :: binary(), id :: integer(), stream :: Enum.t(), part? :: boolean()) ::
              :ok | {:error, String.t()}
  @callback get(user :: binary(), id :: integer()) :: {:ok, binary()} | {:error, String.t()}
  @callback get_stream(user :: binary(), id :: integer()) :: {:ok, Enum.t()} | {:error, String.t()}
  @callback get_stream(user :: binary(), id :: integer(), dest :: Path.t()) ::
              :ok | {:error, String.t()}
  @callback del(user :: binary(), id :: integer()) :: :ok | {:error, String.t()}
  @callback del_all(user :: binary()) :: :ok | {:error, String.t()}
  @callback exists?(user :: binary(), id :: integer()) :: boolean()
  @callback list(user :: binary()) :: {:ok, list(map())} | {:error, String.t()}
end
