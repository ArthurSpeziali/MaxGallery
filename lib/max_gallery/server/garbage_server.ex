defmodule MaxGallery.Server.GarbageServer do
    use GenServer

    @mod __MODULE__
    @path "/tmp/max_gallery/zips/"
    @time_delete 60 # Minutes
    @time_check 10 * 60 * 1000  # Miliseconds


    def start_link(_opts \\ nil) do
        GenServer.start_link(@mod, 0, name: @mod)
    end

    def init(_state) do
        File.mkdir_p(@path)
        count = File.ls!(@path)
                |> Enum.count()


        ## Once an hour, the function checks if exists any "lost" file. 
        Process.send_after(self(), :check, @time_check)
        {:ok, count}
    end


    def handle_call(:count, _from, state) do
        {:reply, state, state}
    end

    def handle_info(:check, _state) do
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


    def check(), do: send(@mod, :check)
    def count(), do: GenServer.call(@mod, :count)

end
