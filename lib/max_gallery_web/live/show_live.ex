defmodule MaxGalleryWeb.ShowLive do
    use MaxGalleryWeb, :live_view
    alias MaxGallery.Server.LiveServer
    alias MaxGallery.Phantom
    alias MaxGallery.Context


    def mount(%{"id" => id}, _session, socket) do
        key = LiveServer.get(:auth_key)

        {:ok, querry} = Context.decrypt_one(id, key) 
        data = Phantom.encode_bin(querry)
               |> List.first()

        
        socket = assign(socket, [
            data: data,
            id: id
        ])

        {:ok, socket, layout: false}
    end
    def mount(_params, _session, socket) do
        {:ok, push_navigate(socket, to: "/data")}
    end


    def handle_event("cancel", _params, socket) do
        {:noreply,
            push_navigate(socket, to: "/data")
        }
    end
end
