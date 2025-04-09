defmodule MaxGalleryWeb.EditorLive do
    use MaxGalleryWeb, :live_view
    alias MaxGallery.Server.LiveServer

    def mount(%{"id" => id}, _session, socket) do
        socket = assign(socket, [
            content: LiveServer.get()[:content],
            name: LiveServer.get()[:name],
            id: id,
            edit_iframe: false
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
        {id, name, content}

        {:noreply, 
            push_navigate(socket, to: "/data")
        }
    end
end
