defmodule MaxGallery.Encrypter.Chacha20 do
  alias MaxGallery.Variables
  @nonce_size 8

  def encrypt(data, key) do
    nonce = gen_nounce()
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
    nonce = gen_nounce()
    key = hash(key)
    params = {key, nonce, 0, ""}

    {:ok, agent} =
      Agent.start_link(fn ->
        {"", params}
      end)

    File.open(dest, [:write], fn output ->
      File.stream!(path, Variables.chunk_size(), [:read])
      |> Stream.each(fn chunk ->
        {acc, params} = Agent.get(agent, fn state -> state end)
        {new_acc, new_params} = Chacha20.crypt_bytes(chunk, params, [acc])

        Agent.update(agent, fn _state ->
          {new_acc, new_params}
        end)

        IO.binwrite(output, new_acc)
      end)
      |> Stream.run()
    end)

    nonce
  end

  @spec encrypt_stream(path :: Path.t(), key :: String.t()) :: {Stream.t(), binary()}
  def encrypt_stream(path, key) do
    nonce = gen_nounce()
    key = hash(key)
    params = {key, nonce, 0, ""}

    {:ok, agent} =
      Agent.start_link(fn ->
        {"", params}
      end)

    stream =
      File.stream!(path, Variables.chunk_size(), [:read])
      |> Stream.map(fn chunk ->
        {acc, params} = Agent.get(agent, fn state -> state end)
        {new_acc, new_params} = Chacha20.crypt_bytes(chunk, params, [acc])

        Agent.update(agent, fn _state ->
          {new_acc, new_params}
        end)

        new_acc
      end)

    {nonce, stream}
  end


  def decrypt_stream(path, dest, nonce, key) do
    key = hash(key)
    params = {key, nonce, 0, ""}

    {:ok, agent} =
      Agent.start_link(fn ->
        {"", params}
      end)

    File.open(dest, [:write], fn output ->
      File.stream!(path, Variables.chunk_size(), [:read])
      |> Stream.each(fn chunk ->
        {acc, params} = Agent.get(agent, fn state -> state end)
        {new_acc, new_params} = Chacha20.crypt_bytes(chunk, params, [acc])

        Agent.update(agent, fn _state ->
          {new_acc, new_params}
        end)

        IO.binwrite(output, new_acc)
      end)
      |> Stream.run()
    end)

    :ok
  end

  @spec decrypt_stream(stream :: Stream.t(), nonce :: binary(), key :: String.t()) :: Stream.t()
  def decrypt_stream(stream, nonce, key) do
    key = hash(key)
    params = {key, nonce, 0, ""}

    {:ok, agent} =
      Agent.start_link(fn ->
        {"", params}
      end)

    out_stream = 
      Stream.map(stream, fn chunk ->
        {acc, params} = Agent.get(agent, fn state -> state end)
        {new_acc, new_params} = Chacha20.crypt_bytes(chunk, params, [acc])

        Agent.update(agent, fn _state ->
          {new_acc, new_params}
        end)

        new_acc
      end)

    out_stream
  end

  def hash(data) do

    :crypto.hash(:sha256, data)
  end

  def gen_nounce() do
    :crypto.strong_rand_bytes(@nonce_size)
  end
end
