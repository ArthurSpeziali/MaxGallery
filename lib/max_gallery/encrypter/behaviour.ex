defmodule MaxGallery.Encrypter.Behaviour do
  @moduledoc """
  Behaviour for encryption operations.
  """

  @callback encrypt(data :: binary(), key :: binary()) :: {binary(), binary()}
  @callback decrypt(encrypted_data :: binary(), iv :: binary(), key :: binary()) :: binary()
  @callback encrypt_stream(path_or_data :: binary(), key :: binary()) :: {Enumerable.t(), binary()}
  @callback decrypt_stream(stream :: Enumerable.t(), iv :: binary(), key :: binary()) :: Enumerable.t()
  @callback hash(data :: binary()) :: binary()
  @callback random() :: binary()
end