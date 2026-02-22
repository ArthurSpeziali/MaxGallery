defmodule MaxGallery.Encrypter.Mock do
  @moduledoc """
  Mock implementation of Encrypter for faster tests.
  Uses simple transformations instead of real encryption.
  """

  @behaviour MaxGallery.Encrypter.Behaviour

  # Simple deterministic "encryption" for tests
  def encrypt(data, _key) when is_binary(data) do
    iv = :crypto.strong_rand_bytes(16)
    encrypted = Base.encode64(data)
    {iv, encrypted}
  end

  def decrypt(encrypted_data, _iv, _key) when is_binary(encrypted_data) do
    case Base.decode64(encrypted_data) do
      {:ok, decrypted} -> decrypted
      :error -> encrypted_data  # Return as-is if not base64
    end
  end

  def encrypt_stream(path, _key) when is_binary(path) do
    # For tests, just read the file and create a simple stream
    content = File.read!(path)
    iv = :crypto.strong_rand_bytes(16)
    encrypted_content = Base.encode64(content)
    
    # Create a simple stream that yields the encrypted content
    stream = Stream.unfold(encrypted_content, fn
      "" -> nil
      data -> {data, ""}
    end)
    
    {stream, iv}
  end

  def encrypt_stream(data, _key) when is_binary(data) do
    iv = :crypto.strong_rand_bytes(16)
    encrypted_content = Base.encode64(data)
    
    stream = Stream.unfold(encrypted_content, fn
      "" -> nil
      data -> {data, ""}
    end)
    
    {stream, iv}
  end

  def decrypt_stream(stream, _iv, _key) do
    # For tests, just decode the base64 content
    Stream.map(stream, fn chunk ->
      case Base.decode64(chunk) do
        {:ok, decrypted} -> decrypted
        :error -> chunk
      end
    end)
  end

  def hash(data) when is_binary(data) do
    # Simple hash for tests
    :crypto.hash(:sha256, data)
  end

  def random do
    :crypto.strong_rand_bytes(16)
  end
end