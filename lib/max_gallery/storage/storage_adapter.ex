defmodule MaxGallery.StorageAdapter do
  @moduledoc """
  Adapter that delegates to the appropriate storage implementation based on environment.
  Uses mock storage for tests and real S3 storage for production.
  """

  @doc "Returns the appropriate storage implementation based on current environment."
  @spec impl() :: module()
  def impl do
    case Mix.env() do
      :test -> MaxGallery.Storage.Mock
      _ -> MaxGallery.Storage
    end
  end

  @doc "Stores binary data for a user's file."
  @spec put(user :: binary(), id :: integer(), blob :: binary()) :: :ok | {:error, any()}
  def put(user, id, blob), do: impl().put(user, id, blob)

  @doc "Stores streaming data for a user's file."
  @spec put_stream(user :: binary(), id :: integer(), stream :: Enumerable.t()) :: :ok | {:error, any()}
  def put_stream(user, id, stream), do: impl().put_stream(user, id, stream)

  @doc "Retrieves binary data for a user's file."
  @spec get(user :: binary(), id :: integer()) :: {:ok, binary()} | {:error, any()}
  def get(user, id), do: impl().get(user, id)

  @doc "Retrieves streaming data for a user's file."
  @spec get_stream(user :: binary(), id :: integer()) :: {:ok, Enumerable.t()} | {:error, any()}
  def get_stream(user, id), do: impl().get_stream(user, id)

  @doc "Retrieves streaming data and writes to destination."
  @spec get_stream(user :: binary(), id :: integer(), dest :: Path.t()) :: :ok | {:error, any()}
  def get_stream(user, id, dest), do: impl().get_stream(user, id, dest)

  @doc "Deletes a user's file from storage."
  @spec del(user :: binary(), id :: integer()) :: :ok | {:error, any()}
  def del(user, id), do: impl().del(user, id)

  @doc "Deletes all files for a user from storage."
  @spec del_all(user :: binary()) :: :ok | {:error, any()}
  def del_all(user), do: impl().del_all(user)

  @doc "Checks if a user's file exists in storage."
  @spec exists?(user :: binary(), id :: integer()) :: boolean()
  def exists?(user, id), do: impl().exists?(user, id)

  @doc "Lists all file IDs for a user."
  @spec list(user :: binary()) :: {:ok, [integer()]} | {:error, any()}
  def list(user), do: impl().list(user)
end
