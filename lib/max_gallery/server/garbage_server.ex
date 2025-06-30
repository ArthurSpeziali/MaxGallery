defmodule MaxGallery.Server.GarbageServer do
    use GenServer

    @mod __MODULE__
    @path %{zips: "/tmp/max_gallery/zips/", cache: "/tmp/max_gallery/zips/"}
    @time_delete %{zips: 75, cache: 120} # 75-120 Minutes
    @time_check 5 * 60 * 1000  # 5 Minutes


    def start_link(_opts \\ nil) do
        GenServer.start_link(@mod, 0, name: @mod)
    end

    def init(_state) do
        File.mkdir_p(@path.zips)
        count = (File.ls!(@path.zips)
                |> Enum.count()) + (File.ls!(@path.cache) 
                |> Enum.count())


        ## Once a 10 minutes, the function checks if exists any "lost" file. 
        Process.send_after(self(), :check_zips, @time_check)
        Process.send_after(self(), :check_cache, @time_check)
        {:ok, count}
    end


    def handle_call(:count, _from, state) do
        {:reply, state, state}
    end

    def handle_info(:check_zips, _state) do
        now = NaiveDateTime.utc_now()
        files = File.ls!(@path.zips)

        for name <- files do
            time = File.stat!(@path.zips <> name)
                   |> Map.fetch!(:ctime)
                   |> NaiveDateTime.from_erl!()

            diff = NaiveDateTime.diff(now, time, :minute)
            if diff >= @time_delete.zips do
                File.rm(@path.zips <> name)
            end
        end

        count = File.ls!(@path.zips)
                |> Enum.count()

        {:noreply, count}
    end
    def handle_info(:check_cache, _state) do
        now = NaiveDateTime.utc_now()
        files = File.ls!(@path.cache)

        for name <- files do
            time = File.stat!(@path.cache <> name)
                   |> Map.fetch!(:ctime)
                   |> NaiveDateTime.from_erl!()

            diff = NaiveDateTime.diff(now, time, :minute)
            if diff >= @time_delete.cache do
                File.rm(@path.cache <> name)
            end
        end

        count = File.ls!(@path.cache)
                |> Enum.count()

        {:noreply, count}
    end


    def check() do 
        send(@mod, :check_cache) 
        send(@mod, :check_zips)
    end
    def count(), do: GenServer.call(@mod, :count)

end
