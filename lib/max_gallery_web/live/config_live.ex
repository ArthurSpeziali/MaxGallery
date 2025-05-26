defmodule MaxGalleryWeb.ConfigLive do
    use MaxGalleryWeb, :live_view
    alias MaxGallery.Server.LiveServer


    def mount(_params, _session, socket) do
        key = LiveServer.get(:auth_key)

        if key do
            {:ok, socket, layout: false}
        else
            {:ok, 
                push_navigate(socket, to: "/")
            }
        end
    end


    def handle_event("cancel", _params, socket) do
        {:noreply, 
            push_navigate(socket, to: "/data")
        }
    end
end
