defmodule MaxGalleryWeb.ImportLive do
    ## Module for site's import files page.
    use MaxGalleryWeb, :live_view
    alias MaxGallery.Server.LiveServer
    alias MaxGallery.Context
    alias MaxGallery.Utils
    alias MaxGallery.Variables


    def mount(params, _session, socket) do
        group_id = Map.get(params, "id")

        zip? = Map.get(params, "zip")
        limit = if zip? do
            1
        else
            64
        end
        accepts = if zip? do
            ~w(.zip)
        else
            :any
        end


        socket = allow_upload(
            socket,
            :file_import,
            accept: accepts,
            max_entries: limit,
            max_file_size: Variables.file_size
        ) |> assign(
            loading: false,
            zip: zip?,
            page_id: group_id
        )

        {:ok, socket, layout: false}
    end


    ## Function for display file's name in the web.
    def name_files(uploads, zip?) do
        entries = uploads.file_import.entries

        case {entries, zip?} do
            {[], nil} -> 
                "Nenhum arquivo selecionado."

            {[], _zip} ->
                "Nenhum arquivo \".zip\" selecionado."

            _entry -> 
                Enum.map(entries, fn item -> 
                    "\"#{item.client_name}\""
                end) |> Enum.join(", ")
        end
    end


    def handle_event("validate", _params, socket) do
        {:noreply, socket}
    end

    def handle_event("upload", _params, socket) do
        key = LiveServer.get(:auth_key)
        group_id = socket.assigns[:page_id]
        zip? = socket.assigns[:zip]

        consume_uploaded_entries(socket, :file_import, 
            fn %{path: path}, %{client_name: name} -> 
                if zip? do
                    if Utils.zip_valid?(path) do
                        Context.unzip_content(path, key, group: group_id)
                    else
                        File.rm!(path)
                    end
                else
                    Context.cypher_insert(path, key, name: name, group: group_id)
                end

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
