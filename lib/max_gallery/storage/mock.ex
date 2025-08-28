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
  def put(user, id, blob) do
    ensure_started()
    key = generate_key(user, id)

    Agent.update(__MODULE__, fn state ->
      Map.put(state, key, blob)
    end)

    {:ok, key}
  end

  @impl true
  def get(user, id) do
    ensure_started()
    key = generate_key(user, id)

    case Agent.get(__MODULE__, fn state -> Map.get(state, key) end) do
      nil -> {:error, "File not found"}
      blob -> {:ok, blob}
    end
  end

  @impl true
  def del(user, id) do
    ensure_started()
    key = generate_key(user, id)

    Agent.update(__MODULE__, fn state ->
      Map.delete(state, key)
    end)

    :ok
  end

  @impl true
  def del_all(user) do
    ensure_started()
    prefix = "encrypted_files/#{user}/"

    deleted_count =
      Agent.get_and_update(__MODULE__, fn state ->
        {to_delete, to_keep} =
          Enum.split_with(state, fn {key, _blob} ->
            String.starts_with?(key, prefix)
          end)

        {length(to_delete), Map.new(to_keep)}
      end)

    {:ok, deleted_count}
  end

  @impl true
  def exists?(user, id) do
    ensure_started()
    key = generate_key(user, id)
    Agent.get(__MODULE__, fn state -> Map.has_key?(state, key) end)
  end

  @impl true
  def list(user) do
    ensure_started()
    prefix = "encrypted_files/#{user}/"

    files =
      Agent.get(__MODULE__, fn state ->
        state
        |> Enum.filter(fn {key, _blob} -> String.starts_with?(key, prefix) end)
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

  defp generate_key(user, id) do
    if id do
      "encrypted_files/#{user}/#{id}"
    else
      "encrypted_files/#{user}"
    end
  end
end
