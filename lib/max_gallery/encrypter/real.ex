defmodule MaxGallery.Encrypter.Real do
  @moduledoc """
  Real encryption implementation using AES-256-CTR.
  """
  
  @behaviour MaxGallery.Encrypter.Behaviour
  
  alias MaxGallery.Variables

  @impl true
  def encrypt(data, key) do
    iv = :crypto.strong_rand_bytes(16)
    hash_key = hash(key)

    cypher = :crypto.crypto_one_time(:aes_256_ctr, hash_key, iv, data, true)
    {iv, cypher}
  end

  @impl true
  def decrypt(cypher, iv, key) do
    hash_key = hash(key)

    :crypto.crypto_one_time(:aes_256_ctr, hash_key, iv, cypher, false)
  end

  @impl true
  def encrypt_stream(path, key) do
    iv = random()
    key = hash(key)
    ref = :crypto.crypto_init(:aes_ctr, key, iv, true)

    stream =
      File.stream!(path, Variables.chunk_size())
      |> Stream.map(fn chunk ->
        :crypto.crypto_update(ref, chunk)
      end)

    :crypto.crypto_final(ref)
    {stream, iv}
  end

  @impl true
  def decrypt_stream(stream, iv, key) do
    key = hash(key)
    ref = :crypto.crypto_init(:aes_ctr, key, iv, false)

    stream =
      Stream.map(stream, fn chunk ->
        :crypto.crypto_update(ref, chunk)
      end)

    :crypto.crypto_final(ref)
    stream
  end

  @impl true
  def hash(key) do
    :crypto.hash(:sha256, key)
  end

  @impl true
  def random(bytes \\ 16) when bytes > 0 do
    :crypto.strong_rand_bytes(bytes)
  end
end