defmodule MaxGalleryWeb.EditorLive do
    use MaxGalleryWeb, :live_view
    alias MaxGallery.Server.LiveServer
    alias MaxGallery.Context
    alias MaxGallery.Phantom
    alias MaxGallery.Extension


    def mount(%{"id" => id}, _session, socket) do
        key = LiveServer.get(:auth_key)
        page_id = LiveServer.get(:page_id)

        {:ok, lazy_data} = Context.decrypt_one(id, key, lazy: true)

        ext = Map.fetch!(lazy_data, :ext) 
                |> Extension.get_ext()

        lazy? = 
            if ext == "text" do
                nil
            else
                true
            end


        {:ok, querry} = Context.decrypt_one(id, key, lazy: lazy?)
        data = Phantom.encode_bin(querry)
               |> List.first()

        socket = assign(socket, [
            data: data,
            id: id,
            page_id: page_id,
            edit_iframe: false,
            new_content: false
        ])

        {:ok, socket, layout: false}
    end
    def mount(_params, _session, socket) do
        page_id = socket.assigns[:page_id]

        {:ok, 
            push_navigate(socket, to: "/data/#{page_id}")
        }
    end


    def handle_event("ask_edit", _params, socket) do
        {:noreply, assign(socket, edit_iframe: true)}
    end

    def handle_event("cancel_edit", _params, socket) do
        {:noreply, assign(socket, edit_iframe: false)}
    end

    def handle_event("redirect_edit", _params, socket) do
        page_id = socket.assigns[:page_id]

        {:noreply, 
            push_navigate(socket, to: "/data/#{page_id}")
        }
    end

    def handle_event("confirm_edit", %{"new_content" => content, "new_name" => name}, socket) do
        id = socket.assigns[:id]
        key = LiveServer.get(:auth_key)
        page_id = socket.assigns[:page_id]

        Context.cypher_update(id, %{name: name, blob: content}, key)
        {:noreply, 
            push_navigate(socket, to: "/data/#{page_id}")
        }
    end
    def handle_event("confirm_edit", %{"new_name" => name}, socket) do
        id = socket.assigns[:id]
        key = LiveServer.get(:auth_key)
        page_id = socket.assigns[:page_id]

        Context.cypher_update(id, %{name: name}, key)
        {:noreply, 
            push_navigate(socket, to: "/data/#{page_id}")
        }
    end

    def handle_event("update_content", %{"new_content" => content}, socket) do
        {:noreply, assign(socket, new_content: content)}
    end
    def handle_event("update_content", _params, socket) do
        {:noreply, socket}
    end
end
