defmodule MaxGallery.Server.LiveServer do
    use GenServer
    @mod __MODULE__


    def start_link(_opts \\ nil) do
        GenServer.start_link(@mod, %{}, name: @mod)
    end

    def init(state) do
        {:ok, state}
    end


    def handle_call(:all, _from, state) do
        {:reply, state, state}
    end
    
    def handle_call({:get, key}, _from, state) do
        {:reply, state[key], state}
    end

    def handle_cast({:put, map}, state) do
        {:noreply, Map.merge(state, map)}
    end

    def handle_cast({:del, key}, state) do
        {:noreply, Map.delete(state, key)}
    end

    def handle_cast(:clr, _state) do
        {:noreply, %{}}
    end


    def all() do
        GenServer.call(@mod, :all)
    end

    def get(key) do
        GenServer.call(@mod, {:get, key})
    end

    def put(map) do
        GenServer.cast(@mod, {:put, map})
    end

    def del(key) do
        GenServer.cast(@mod, {:del, key})
    end

    def clr() do
        GenServer.cast(@mod, :clr)
    end

end
