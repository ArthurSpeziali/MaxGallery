defmodule MaxGalleryWeb.ImportLive do
    use MaxGalleryWeb, :live_view
    alias MaxGallery.Server.LiveServer
    alias MaxGallery.Context

    def name_files(uploads) do
        entries = uploads.file_import.entries

        case entries do
            [] -> 
                "Nenhum arquivo selecionado."

            _entry -> 
                Enum.map(entries, fn item -> 
                    "\"#{item.client_name}\""
                end) |> Enum.join(", ")
        end
    end


    def mount(params, _session, socket) do
        group_id = Map.get(params, "id")

        socket = allow_upload(
            socket,
            :file_import,
            accept: :any,
            max_entries: 64,
            max_file_size: 2*10**9
        ) |> assign(
            loading: false,
            page_id: group_id
        )

        {:ok, socket, layout: false}
    end


    def handle_event("validate", _params, socket) do
        {:noreply, socket}
    end

    def handle_event("upload", _params, socket) do
        key = LiveServer.get(:auth_key)
        group_id = socket.assigns[:page_id]

        consume_uploaded_entries(socket, :file_import, 
            fn %{path: path}, %{client_name: name} -> 
                Context.cypher_insert(path, key, name: name, group: group_id)

                {:ok, nil}
            end)

        {:noreply, 
            push_navigate(socket, to: "/data/#{group_id}")
        }
    end

    def handle_event("cancel", _params, socket) do
        page_id = socket.assigns[:page_id]

        socket = assign(socket, loading: false)
        {:noreply,
            push_navigate(socket, to: "/data/#{page_id}")
        }
    end

    def handle_event("loading", _params, socket) do
        {:noreply, assign(socket, loading: true)}
    end
end
