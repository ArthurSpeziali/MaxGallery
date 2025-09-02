defmodule MaxGallery.Encrypter do
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

  def encrypt_stream(path, new_path, key) do
    nonce = gen_nounce()
    key = hash(key)
    params = {key, nonce, 0, ""}

    {:ok, agent} =
      Agent.start_link(fn ->
        {"", params}
      end)

    File.open(new_path, [:write], fn output ->
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

  def decrypt_stream(path, new_path, nonce, key) do
    key = hash(key)
    params = {key, nonce, 0, ""}

    {:ok, agent} =
      Agent.start_link(fn ->
        {"", params}
      end)

    File.open(new_path, [:write], fn output ->
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

  def hash(data) do
    :crypto.hash(:sha256, data)
  end

  def gen_nounce() do
    :crypto.strong_rand_bytes(@nonce_size)
  end
end
