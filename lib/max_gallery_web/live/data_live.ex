defmodule MaxGalleryWeb.DataLive do
    ## Module for the site's main page.
    use MaxGalleryWeb, :live_view
    alias MaxGallery.Context
    alias MaxGallery.Server.LiveServer
    alias MaxGallery.Extension
    alias MaxGallery.Utils



    def mount(params, %{"auth_key" => key}, socket) do
        LiveServer.put(%{auth_key: key})
        group_id = Map.get(params, "id")

        {:ok, lazy_datas} = Context.decrypt_all(key, lazy: true, group: group_id)

        socket = assign(socket, [
            datas: lazy_datas,
            lock_datas: lazy_datas,
            page_id: group_id,
            delete_iframe: nil,
            rename_iframe: nil,
            remove_iframe: nil,
            more_iframe: nil,
            info_iframe: nil
        ])

        {:ok, socket, layout: false}
    end
    def mount(_params, _session, socket) do
        {:ok, 
            push_navigate(socket, to: "/")
        }
    end

    
    def handle_event("ask_delete", %{"id" => id, "name" => name}, socket) do
        {:noreply,
            assign(socket, delete_iframe: id, name_data: name)
        }
    end

    def handle_event("cancel", _params, socket) do
        socket = assign(socket,
            delete_iframe: nil,
            rename_iframe: nil,
            remove_iframe: nil,
            more_iframe: nil,
            info_iframe: nil
        )

        {:noreply, socket}
    end

    def handle_event("confirm_delete", %{"id" => id}, socket) do
        key = LiveServer.get(:auth_key)
        page_id = socket.assigns[:page_id]
        Context.cypher_delete(id, key)

        {:noreply,
            push_navigate(socket, to: "/data/#{page_id}")
        }
    end

    def handle_event("editor", %{"id" => id}, socket) do
        page_id = socket.assigns[:page_id]
        LiveServer.put(%{page_id: page_id})

        {:noreply,
            push_navigate(socket, to: "/editor?id=#{id}")
        }
    end

    def handle_event("show", %{"id" => id}, socket) do
        page_id = socket.assigns[:page_id]
        LiveServer.put(%{page_id: page_id})

        {:noreply,
            push_navigate(socket, to: "/show?id=#{id}")
        }
    end

    def handle_event("import_file", _params, socket) do
        page_id = socket.assigns[:page_id]

        {:noreply,
            push_navigate(socket, to: "/import/#{page_id}")
        }
    end

    def handle_event("ask_rename", %{"id" => id, "name" => name}, socket) do
        socket = assign(socket,
            rename_iframe: id,
            name_group: name
        )

        {:noreply, socket}
    end

    def handle_event("confirm_rename", %{"id" => id, "new_name" => name}, socket) do
        key = LiveServer.get(:auth_key)
        page_id = socket.assigns[:page_id]
        Context.group_update(id, %{name: name}, key)

        {:noreply, 
            push_navigate(socket, to: "/data/#{page_id}")
        }
    end

    def handle_event("ask_remove", %{"id" => id, "name" => name}, socket) do
        socket = assign(socket, 
            remove_iframe: id,
            name_group: name
        )

        {:noreply, socket} 
    end

    def handle_event("confirm_remove", %{"id" => id}, socket) do
        key = LiveServer.get(:auth_key)
        page_id = socket.assigns[:page_id]
        Context.group_delete(id, key)

        {:noreply, 
            push_navigate(socket, to: "/data/#{page_id}")
        }
    end

    def handle_event("redirect", _params, socket) do
        page_id = socket.assigns[:page_id]

        {:noreply, 
            push_navigate(socket, to: "/data/#{page_id}")
        }
    end

    def handle_event("open", %{"id" => id}, socket) do
        {:noreply,
            push_navigate(socket, to: "/data/#{id}")
        }
    end

    def handle_event("back", _params, socket) do
        back_id = socket.assigns[:page_id]
                  |> Utils.get_back()

        {:noreply,
            push_navigate(socket, to: "/data/#{back_id}")
        }
    end

    def handle_event("ask_folder", _params, socket) do
        socket = assign(socket,
            ## Reuses the same variable to create groups.
            rename_iframe: :create,
            name_group: ""
        )

        {:noreply, socket}
    end

    def handle_event("confirm_folder", %{"new_name" => name}, socket) do
        key = LiveServer.get(:auth_key)
        page_id = socket.assigns[:page_id]
        Context.group_insert(name, key, group: page_id)

        {:noreply, 
            push_navigate(socket, to: "/data/#{page_id}")
        }
    end

    def handle_event("more_menu", %{"id" => id, "type" => type}, socket) do
        {:noreply,
            assign(socket, more_iframe: id, type: type)
        }
    end

    def handle_event("move", %{"id" => id}, socket) do
        page_id = socket.assigns[:page_id]
        type = socket.assigns[:type]
        LiveServer.put(%{object_info: %{
            id: id,
            type: type
        }})

        {:noreply,
            push_navigate(socket, to: "/move/#{page_id}?action=move")
        }
    end

    def handle_event("copy", %{"id" => id}, socket) do
        page_id = socket.assigns[:page_id]
        type = socket.assigns[:type]

        LiveServer.put(%{object_info: %{
            id: id,
            type: type
        }})

        {:noreply,
            push_navigate(socket, to: "/move/#{page_id}?action=copy")
        }
    end

    def handle_event("info", %{"id" => id}, socket) do
        key = LiveServer.get(:auth_key)
        type = socket.assigns[:type]

        group? = 
            if type == "group" do
                true
            else
                nil
            end
        {:ok, object} = Context.decrypt_one(id, key, group: group?, lazy: true)

        size = Utils.get_size(id, group: group?)
               |> Extension.convert_size()

        group_name = 
            if object.group do
                {:ok, querry} = Context.decrypt_one(object.group, key, group: true)
                Map.fetch!(querry, :name)
            else
                "Main"
            end


        ## Adjusts the NaiveDateTime to be displayed on the web.
        %{inserted_at: inserted_at, updated_at: updated_at} = Utils.get_timestamps(id, group: group?)
        timestamps = %{
            inserted_at: NaiveDateTime.to_string(inserted_at),
            updated_at: NaiveDateTime.to_string(updated_at)
        }

        socket = assign(socket,
            info_iframe: true,
            more_iframe: nil,
            object: object,
            size: size,
            group_name: group_name,
            timestamps: timestamps
        )

        {:noreply, socket}
    end

    def handle_event("search", %{"search" => search}, socket) do
        querry = socket.assigns[:lock_datas]
                 |> Utils.get_like(search)

        {:noreply, 
            assign(socket, datas: querry)
        }
    end
end
