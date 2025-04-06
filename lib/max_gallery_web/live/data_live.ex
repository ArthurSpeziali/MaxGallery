defmodule MaxGalleryWeb.DataLive do
    use MaxGalleryWeb, :live_view
    alias MaxGallery.Context


    def mount(_params, %{"auth_key" => key}, socket) do
        {:ok, datas} = Context.decrypt_all(key)

        socket = assign(socket, [
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
        Context.cypher_delete(id)

        {:noreply,
            push_navigate(socket, to: "/data")
        }
    end

end
