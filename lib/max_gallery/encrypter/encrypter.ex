defmodule MaxGallery.Encrypter do
  alias MaxGallery.Variables
  @nonce_size 8

  def encrypt(data, key) do
    nonce = gen_nonce()
    key = hash(key)

    {nonce, Chacha20.crypt(data, key, nonce)}
  end

  def decrypt(data, nonce, key) do
    key = hash(key)

    Chacha20.crypt(data, key, nonce)
  end

  # def encrypt_seq(data, nonce, key, seq \\ 0) do
  #   params = {key, nonce, seq, ""}

  #   Chacha20.crypt_bytes(data, )
  # end

  @spec encrypt_stream(path :: Path.t(), dest :: Path.t(), key :: String.t()) :: binary() 
  def encrypt_stream(path, dest, key) when is_binary(path) and is_binary(dest) do
    nonce = gen_nonce()
    key = hash(key)
    params = {key, nonce, 0, ""}

    File.open(dest, [:write], fn output ->
      File.stream!(path, Variables.chunk_size(), [:read])
      |> Enum.reduce(params, fn chunk, params ->
        {cont, new_params} = Chacha20.crypt_bytes(chunk, params, [])

        IO.binwrite(output, cont)
        new_params
      end)
    end)

    nonce
  end

  @spec encrypt_stream(path :: Path.t(), key :: String.t()) :: {struct(), binary()}
  def encrypt_stream(path, key) do
    nonce = gen_nonce()
    key = hash(key)
    params = {key, nonce, 0, ""}

    stream  =
      File.stream!(path, Variables.chunk_size(), [:read])
      |> Stream.transform(params, fn chunk, params ->
        {cont, new_params} = Chacha20.crypt_bytes(chunk, params, [])

        {[cont], new_params}
      end)

    {stream, nonce}
  end


  def decrypt_stream(path, dest, nonce, key) do
    key = hash(key)
    params = {key, nonce, 0, ""}

    File.open(dest, [:write], fn output ->
      File.stream!(path, Variables.chunk_size(), [:read])
      |> Enum.reduce(params, fn chunk, params ->
        {cont, new_params} = Chacha20.crypt_bytes(chunk, params, [])

        IO.binwrite(output, cont)
        new_params
      end)
    end)

    :ok
  end

  @spec decrypt_stream(stream :: struct(), nonce :: binary(), key :: String.t()) :: struct()
  def decrypt_stream(stream, nonce, key) do
    key = hash(key)
    params = {key, nonce, 0, ""}

    out_stream = 
      Stream.transform(stream, params, fn chunk, params ->
        {cont, new_params} = Chacha20.crypt_bytes(chunk, params, [])

        {[cont], new_params}
      end)

    out_stream
  end

  def hash(data) do

    :crypto.hash(:sha256, data)
  end

  def gen_nonce(bytes \\ @nonce_size) do
    :crypto.strong_rand_bytes(bytes)
  end

end
