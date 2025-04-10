defmodule MaxGalleryWeb.EditorLive do
    use MaxGalleryWeb, :live_view
    alias MaxGallery.Server.LiveServer
    alias MaxGallery.Context
    alias MaxGallery.Phantom


    def mount(%{"id" => id}, _session, socket) do
        data = LiveServer.get(:datas)
                  |> Enum.find(fn item -> 
                      to_string(item.id) == id
                  end) |> Phantom.encode_bin() 
                  |> List.first()

        socket = assign(socket, [
            data: data,
            auth_key: LiveServer.get(:auth_key),
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
        key = socket.assigns[:auth_key]

        Context.cypher_update(id, %{name: name, blob: content}, key)

        {:noreply, 
            push_navigate(socket, to: "/data")
        }
    end
end
