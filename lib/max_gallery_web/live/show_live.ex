defmodule MaxGalleryWeb.ShowLive do
    ## Module for site's contents show page.
    use MaxGalleryWeb, :live_view
    alias MaxGallery.Server.LiveServer
    alias MaxGallery.Phantom
    alias MaxGallery.Context
    alias MaxGallery.Extension


    def mount(%{"id" => id}, _session, socket) do
        key = LiveServer.get(:auth_key)
        page_id = LiveServer.get(:page_id)

        {:ok, raw_querry} = Context.decrypt_one(id, key, lazy: true) 
        lazy = 
            if Extension.get_ext(raw_querry.ext) != "text" do
                true
            else
                nil
            end


        {:ok, querry} = Context.decrypt_one(id, key, lazy: lazy)
        data = Phantom.encode_bin(querry)
               |> List.first()

        
        socket = assign(socket, [
            data: data,
            page_id: page_id,
            id: id
        ])

        {:ok, socket, layout: false}
    end
    def mount(_params, _session, socket) do
        page_id = socket.assigns[:page_id]

        {:ok, push_navigate(socket, to: "/data/#{page_id}")}
    end


    def handle_event("cancel", _params, socket) do
        page_id = socket.assigns[:page_id]
        
        {:noreply,
            push_navigate(socket, to: "/data/#{page_id}")
        }
    end
end
