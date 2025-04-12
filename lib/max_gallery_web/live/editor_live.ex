defmodule MaxGalleryWeb.EditorLive do
    use MaxGalleryWeb, :live_view
    alias MaxGallery.Server.LiveServer
    alias MaxGallery.Context
    alias MaxGallery.Phantom


    def mount(%{"id" => id}, _session, socket) do
        key = LiveServer.get(:auth_key)

        {:ok, querry} = Context.decrypt_one(id, key) 
        data = Phantom.encode_bin(querry)
               |> List.first()

        socket = assign(socket, [
            data: data,
            id: id,
            edit_iframe: false,
            new_content: false
        ])

        {:ok, socket, layout: false}
    end
    def mount(_params, _session, socket) do
        {:ok, 
            push_navigate(socket, to: "/data")
        }
    end


    def handle_event("ask_edit", _params, socket) do
        {:noreply, assign(socket, edit_iframe: true)}
    end

    def handle_event("cancel_edit", _params, socket) do
        {:noreply, assign(socket, edit_iframe: false)}
    end

    def handle_event("redirect_edit", _params, socket) do
        {:noreply, 
            push_navigate(socket, to: "/data")
        }
    end

    def handle_event("confirm_edit", %{"new_content" => content, "new_name" => name}, socket) do
        id = socket.assigns[:id]
        key = LiveServer.get(:auth_key)

        Context.cypher_update(id, %{name: name, blob: content}, key)
        {:noreply, 
            push_navigate(socket, to: "/data")
        }
    end

    def handle_event("update_content", %{"new_content" => content}, socket) do
        {:noreply, assign(socket, new_content: content)}
    end
end
