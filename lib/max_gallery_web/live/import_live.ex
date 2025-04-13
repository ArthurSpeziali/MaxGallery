defmodule MaxGalleryWeb.ImportLive do
    use MaxGalleryWeb, :live_view
    alias MaxGallery.Server.LiveServer
    alias MaxGallery.Context


    def mount(_params, _session, socket) do
        socket = allow_upload(
            socket,
            :file_import,
            accept: :any,
            max_entries: 1,
            max_file_size: 2*10**9
        ) |> assign(
            loading: false
        )

        {:ok, socket, layout: false}
    end


    def handle_event("validate", _params, socket) do
        {:noreply, socket}
    end

    def handle_event("upload", _params, socket) do
        key = LiveServer.get(:auth_key)
        name = socket.assigns.uploads.file_import.entries
               |> List.first()
               |> Map.fetch!(:client_name)

        consume_uploaded_entries(socket, :file_import, 
            fn %{path: path}, _entry -> 

                Context.cypher_insert(path, key, name: name)
                {:ok, nil}
            end)

        {:noreply, 
            push_navigate(socket, to: "/data")
        }
    end

    def handle_event("cancel", _params, socket) do
        socket = assign(socket, loading: false)
        {:noreply,
            push_navigate(socket, to: "/data")
        }
    end

    def handle_event("loading", _params, socket) do
        {:noreply, assign(socket, loading: true)}
    end
end
