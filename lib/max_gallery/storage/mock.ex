defmodule MaxGallery.Storage.Mock do
  @moduledoc """
  Mock implementation of Storage for testing.
  Stores data in memory using an Agent to avoid S3 calls during tests.
  """

  @behaviour MaxGallery.Storage.Behaviour

  use Agent

  def start_link(_opts \\ []) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def stop do
    if Process.whereis(__MODULE__) do
      Agent.stop(__MODULE__)
    end
  end

  def clear do
    if Process.whereis(__MODULE__) do
      Agent.update(__MODULE__, fn _state -> %{} end)
    end
  end

  @impl true
  def put(cypher_id, blob) do
    ensure_started()
    key = generate_key(cypher_id)
    Agent.update(__MODULE__, fn state ->
      Map.put(state, key, blob)
    end)
    {:ok, key}
  end

  @impl true
  def get(cypher_id) do
    ensure_started()
    key = generate_key(cypher_id)
    case Agent.get(__MODULE__, fn state -> Map.get(state, key) end) do
      nil -> {:error, "File not found"}
      blob -> {:ok, blob}
    end
  end

  @impl true
  def del(cypher_id) do
    ensure_started()
    key = generate_key(cypher_id)
    Agent.update(__MODULE__, fn state ->
      Map.delete(state, key)
    end)
    :ok
  end

  @impl true
  def del_all do
    ensure_started()
    count = Agent.get(__MODULE__, fn state -> map_size(state) end)
    Agent.update(__MODULE__, fn _state -> %{} end)
    {:ok, count}
  end

  @impl true
  def exists?(cypher_id) do
    ensure_started()
    key = generate_key(cypher_id)
    Agent.get(__MODULE__, fn state -> Map.has_key?(state, key) end)
  end

  @impl true
  def list do
    ensure_started()
    files = Agent.get(__MODULE__, fn state ->
      state
      |> Enum.map(fn {key, blob} ->
        %{
          file_name: key,
          file_id: key,
          size: byte_size(blob),
          content_type: "application/octet-stream",
          upload_timestamp: System.system_time(:millisecond),
          content_sha1: :crypto.hash(:sha, blob) |> Base.encode16(case: :lower),
          file_info: %{}
        }
      end)
    end)
    {:ok, files}
  end

  defp ensure_started do
    unless Process.whereis(__MODULE__) do
      start_link()
    end
  end

  defp generate_key(cypher_id) do
    if cypher_id do
      "encrypted_files/#{cypher_id}"
    else
      "encrypted_files"
    end
  end
end