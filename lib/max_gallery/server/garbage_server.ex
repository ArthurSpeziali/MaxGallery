defmodule MaxGallery.Server.GarbageServer do
  @moduledoc """
  GenServer responsible for cleaning up temporary files in the system.

  This server periodically checks and removes old files from:
  - zips/ directory (cleaned after 75 minutes)
  - cache/ directory (cleaned after 120 minutes) 
  - downloads/ directory (cleaned after 30 minutes)

  The cleanup runs every 5 minutes automatically.
  """

  use GenServer
  alias MaxGallery.Variables

  @mod __MODULE__
  # Time in minutes for cleanup
  @folders_info %{
    "zips" => 75,
    "cache" => 120,
    "downloads" => 30, 
    "test" => 600
  }
  # 5 Minutes
  @time_check 1 * 60 * 1000

  defp create_folders() do
    for {dir, _time} <- @folders_info do
      File.mkdir_p!(
        Variables.tmp_dir() <> dir
      )
    end
  end

  defp send_interval() do 
    for {dir, _time} <- @folders_info do
      :timer.send_interval(@time_check, self(), {:check_general, dir})
    end
  end



  def start_link(_opts \\ nil) do
    GenServer.start_link(@mod, nil, name: @mod)
  end

  def init(_state) do
    create_folders()
    send_interval()

    {:ok, nil}
  end

  def handle_info({:check_general, dir}, _state) do
    delete = @folders_info[dir]
    now = NaiveDateTime.utc_now()
    path = Variables.tmp_dir() <> dir <> "/"

    files = File.ls!(path)
    for name <- files do
      time =
        File.stat!(path <> name)
        |> Map.fetch!(:ctime)
        |> NaiveDateTime.from_erl!()

      diff = NaiveDateTime.diff(now, time, :minute)

      if diff >= delete do
        File.rm(path <> name)
      end
    end

    {:noreply, nil}
  end



  def check do
    send(@mod, :check_general)
  end
end
