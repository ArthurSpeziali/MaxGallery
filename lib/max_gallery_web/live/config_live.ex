defmodule MaxGalleryWeb.Live.ConfigLive do
    ## Module for the site's settings page.
    use MaxGalleryWeb, :live_view
    alias MaxGallery.Phantom
    alias MaxGallery.Context


    def mount(_params, %{"auth_key" => _key}, socket) do
        socket = assign(socket, 
            changekey_iframe: nil,
            dropdata_iframe: nil,
            loading: nil
        )

        {:ok, socket, layout: false}
    end
    def mount(_params, _session, socket) do
        push_navigate(socket, to: "/user")
    end


    def handle_event("redirect", _params, socket) do
        {:noreply, 
            push_navigate(socket, to: "/user/data")
        }
    end

    def handle_event("cancel", _params, socket) do
        socket = assign(socket, 
            changekey_iframe: nil,
            dropdata_iframe: nil, 
            loading: nil
        )

        {:noreply, socket}
    end

    def handle_event("drop_data", _params, socket) do
        {:noreply, 
            assign(socket, dropdata_iframe: true)
        }
    end

    def handle_event("submit_dropdata", %{"key" => key}, socket) do
        Context.delete_all(key)

        {:noreply, 
            push_navigate(socket, to: "/user/data")
        }
    end

    def handle_event("change_key", _params, socket) do
        {:noreply,
            assign(socket, changekey_iframe: true)
        }
    end

    def handle_event("submit_changekey", %{"new_key" => new_key, "old_key" => key}, socket) do
        if Phantom.insert_line?(key) do
            Context.update_all(key, new_key)
        end

        {:noreply,
            push_navigate(socket, to: "/user/data")
        }
    end

    def handle_event("loading", _params, socket) do
        {:noreply,
            assign(socket, loading: true)
        }
    end

end
