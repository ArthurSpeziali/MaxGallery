defmodule MaxGallery.Server.GarbageServer do
    use GenServer

    @mod __MODULE__
    @path "/tmp/max_gallery/zips/"
    @time_delete 60 # Minutes
    @time_check 10 # Minutes


    def start_link(_opts \\ nil) do
        GenServer.start_link(@mod, 0, name: @mod)
    end

    def init(_state) do
        count = File.ls!(@path)
                |> Enum.count()

        spawn(&check/0)
        {:ok, count}
    end


    def handle_call(:count, _from, state) do
        {:reply, state, state}
    end

    def handle_cast(:check, _state) do
        now = NaiveDateTime.utc_now()
        files = File.ls!(@path)

        for name <- files do
            time = File.stat!(@path <> name)
                   |> Map.fetch!(:ctime)
                   |> NaiveDateTime.from_erl!()

            diff = NaiveDateTime.diff(now, time, :minute)
            if diff >= @time_delete do
                File.rm(@path <> name)
            end
        end

        count = File.ls!(@path)
                |> Enum.count()

        {:noreply, count}
    end


    def check() do
        GenServer.cast(@mod, :check)
    end

    def count() do
        GenServer.call(@mod, :count)
    end


    def wait() do 
        receive do
            :start ->
                check()
                Process.sleep(@time_check * 60 * 100) # Miliseconds
                send(self(), :start)
        end
    end
end
