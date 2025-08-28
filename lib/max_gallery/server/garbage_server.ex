defmodule MaxGallery.Server.GarbageServer do
  @moduledoc """
  GenServer responsible for cleaning up temporary files in the system.

  This server periodically checks and removes old files from:
  - zips/ directory (cleaned after 75 minutes)
  - tests/ directory (cleaned after 120 minutes) 
  - downloads/ directory (cleaned after 30 minutes)

  The cleanup runs every 5 minutes automatically.
  """

  use GenServer
  alias MaxGallery.Cache
  alias MaxGallery.Variables

  @mod __MODULE__
  @path %{
    zips: Variables.tmp_dir() <> "zips/",
    cache: Variables.tmp_dir() <> "cache/",
    downloads: Variables.tmp_dir() <> "downloads/"
  }
  # Time in minutes for cleanup
  @time_delete %{
    zips: 75,
    cache: 120,
    # 30 minutes for downloads
    downloads: 30
  }
  # 5 Minutes
  @time_check 5 * 60 * 1000

  def start_link(_opts \\ nil) do
    GenServer.start_link(@mod, 0, name: @mod)
  end

  def init(_state) do
    File.mkdir_p(@path.zips)
    File.mkdir_p(@path.cache)
    File.mkdir_p(@path.downloads)

    count =
      (File.ls!(@path.zips)
       |> Enum.count()) +
        (File.ls!(@path.cache)
         |> Enum.count()) +
        (File.ls!(@path.downloads)
         |> Enum.count())

    ## Once every 5 minutes, the function checks if exists any "lost" file.
    :timer.send_interval(@time_check, self(), :check_zips)
    :timer.send_interval(@time_check, self(), :check_cache)
    :timer.send_interval(@time_check, self(), :check_downloads)
    {:ok, count}
  end

  def handle_call(:count, _from, state) do
    {:reply, state, state}
  end

  def handle_info(:check_zips, _state) do
    now = NaiveDateTime.utc_now()

    File.mkdir_p(@path.zips)
    files = File.ls!(@path.zips)

    for name <- files do
      time =
        File.stat!(@path.zips <> name)
        |> Map.fetch!(:ctime)
        |> NaiveDateTime.from_erl!()

      diff = NaiveDateTime.diff(now, time, :minute)

      if diff >= @time_delete.zips do
        File.rm(@path.zips <> name)
      end
    end

    count =
      File.ls!(@path.zips)
      |> Enum.count()

    {:noreply, count}
  end

  def handle_info(:check_cache, _state) do
    # Use the new cache cleanup function
    Cache.cleanup_old_files(@time_delete.cache)

    count =
      File.ls!(@path.cache)
      |> Enum.count()

    {:noreply, count}
  end

  def handle_info(:check_downloads, _state) do
    now = NaiveDateTime.utc_now()

    File.mkdir_p(@path.downloads)
    files = File.ls!(@path.downloads)

    for name <- files do
      time =
        File.stat!(@path.downloads <> name)
        |> Map.fetch!(:ctime)
        |> NaiveDateTime.from_erl!()

      diff = NaiveDateTime.diff(now, time, :minute)

      if diff >= @time_delete.downloads do
        File.rm(@path.downloads <> name)
      end
    end

    count =
      File.ls!(@path.downloads)
      |> Enum.count()

    {:noreply, count}
  end

  def check do
    send(@mod, :check_cache)
    send(@mod, :check_zips)
    send(@mod, :check_downloads)
  end

  def count, do: GenServer.call(@mod, :count)
end
