defmodule MaxGalleryWeb.ConfigLive do
    use MaxGalleryWeb, :live_view
    alias MaxGallery.Server.LiveServer
    alias MaxGallery.Phantom
    alias MaxGallery.Context


    def mount(_params, _session, socket) do
        key = LiveServer.get(:auth_key)

        socket = assign(socket, 
            changekey_iframe: nil,
            dropdata_iframe: nil
        )

        if key do
            {:ok, socket, layout: false}
        else
            {:ok, 
                push_navigate(socket, to: "/")
            }
        end
    end


    def handle_event("redirect", _params, socket) do
        {:noreply, 
            push_navigate(socket, to: "/data")
        }
    end

    def handle_event("cancel", _params, socket) do
        socket = assign(socket, 
            changekey_iframe: nil,
            dropdata_iframe: nil
        )

        {:noreply, socket}
    end

    def handle_event("drop_data", _params, socket) do
        socket = assign(socket,
            dropdata_iframe: true
        )

        {:noreply, socket}
    end

    def handle_event("submit_dropdata", %{"key" => key}, socket) do
        if Phantom.insert_line?(key) do
            Context.delete_all()
        end

        {:noreply, 
            push_navigate(socket, to: "/data")
        }
    end
end
