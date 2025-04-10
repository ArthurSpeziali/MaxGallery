defmodule MaxGalleryWeb.DataLive do
    use MaxGalleryWeb, :live_view
    alias MaxGallery.Context
    alias MaxGallery.Server.LiveServer


    def mount(_params, %{"auth_key" => key}, socket) do
        {:ok, datas} = Context.decrypt_all(key)

        socket = assign(socket, [
            auth_key: key,
            datas: datas,
            delete_iframe: nil
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
        key = socket.assigns[:auth_key]
        Context.cypher_delete(id, key)

        {:noreply,
            push_navigate(socket, to: "/data")
        }
    end

    def handle_event("editor", %{"id" => id}, socket) do
        datas = socket.assigns[:datas]
        key = socket.assigns[:auth_key]

        LiveServer.put(%{datas: datas, auth_key: key})

        {:noreply,
            push_navigate(socket, to: "/editor?id=#{id}")
        }
    end

    def handle_event("show", %{"id" => id}, socket) do
        datas = socket.assigns[:datas]
        key = socket.assigns[:auth_key]

        LiveServer.put(%{datas: datas, auth_key: key})

        {:noreply,
            push_navigate(socket, to: "/show?id=#{id}")
        }
    end

end
