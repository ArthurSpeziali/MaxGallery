defmodule MaxGalleryWeb.DataLive do
    use MaxGalleryWeb, :live_view
    alias MaxGallery.Context
    alias MaxGallery.Server.LiveServer


    def mount(_params, %{"auth_key" => key}, socket) do
        LiveServer.put(%{auth_key: key})
        {:ok, lazy_datas} = Context.decrypt_all(key, lazy: true)

        socket = assign(socket, [
            datas: lazy_datas,
            delete_iframe: nil,
            rename_iframe: nil,
            remove_iframe: nil
        ])

        {:ok, socket, layout: false}
    end
    def mount(_params, _session, socket) do
        {:ok, redirect(socket, to: "/")}
    end

    
    def handle_event("ask_delete", %{"id" => id, "name" => name}, socket) do
        {:noreply,
            assign(socket, delete_iframe: id, name_data: name)
        }
    end

    def handle_event("cancel_delete", _params, socket) do
        {:noreply,
            assign(socket, delete_iframe: nil)
        }
    end

    def handle_event("confirm_delete", %{"id" => id}, socket) do
        key = LiveServer.get(:auth_key)
        Context.cypher_delete(id, key)

        {:noreply,
            push_navigate(socket, to: "/data")
        }
    end

    def handle_event("editor", %{"id" => id}, socket) do
        {:noreply,
            push_navigate(socket, to: "/editor?id=#{id}")
        }
    end

    def handle_event("show", %{"id" => id}, socket) do
        {:noreply,
            push_navigate(socket, to: "/show?id=#{id}")
        }
    end

    def handle_event("create_file", _params, socket) do
        {:noreply,
            push_navigate(socket, to: "/import")}
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

        Context.group_update(id, name, key)
        {:noreply,
            push_navigate(socket, to: "/data")
        }
    end

    def handle_event("cancel_rename", _params, socket) do
        {:noreply,
            assign(socket, rename_iframe: nil)
        }
    end

    def handle_event("ask_remove", %{"id" => id, "name" => name}, socket) do
        socket = assign(socket, 
            remove_iframe: id,
            name_group: name
        )

        {:noreply, socket} 
    end

    def handle_event("cancel_remove", _params, socket) do
        {:noreply,
            push_navigate(socket, to: "/data")
        }
    end

    def handle_event("confirm_remove", %{"id" => id}, socket) do
        key = LiveServer.get(:auth_key)
        Context.group_delete(id, key)

        {:noreply,
            push_navigate(socket, to: "/data")
        }
    end
end
