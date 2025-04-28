defmodule MaxGalleryWeb.MoveLive do
    use MaxGalleryWeb, :live_view
    alias MaxGallery.Context
    alias MaxGallery.Server.LiveServer


    def mount(params, _session, socket) do
        page_id = Map.get(params, "id")
        key = LiveServer.get(:auth_key)
        
        {:ok, group_info} = 
            if page_id do 
                Context.decrypt_one(page_id, key, group: true)
            else
                {:ok, %{name: "Main"}}
            end

        {:ok, groups} = Context.decrypt_all(key, only: :groups, group: page_id)

        socket = assign(socket,
            group_name: group_info[:name],
            page_id: page_id,
            groups: groups,
            action: :move
        )


        if LiveServer.get(:data_info) do
            {:ok, socket, layout: false}
        else
            {:ok,
                push_navigate(socket, to: "/data/#{page_id}")
            }
        end
    end

    def handle_event("open", %{"id" => id}, socket) do
        {:noreply,
            push_navigate(socket, to: "/move/#{id}")
        }
    end

    def handle_event("back", _params, socket) do
        back_id = socket.assigns[:page_id]
                  |> Context.get_back()
                  
        {:noreply, 
            push_navigate(socket, to: "/move/#{back_id}")
        }
    end

    def handle_event("select", %{"id" => dest_id}, socket) do
        key = LiveServer.get(:auth_key)
        object = LiveServer.get(:data_info)

        if object.type == :data do
            Context.cypher_update(object.id, %{group_id: dest_id}, key)
        else
            Context.group_update(object.id, %{group_id: dest_id}, key)
        end


        {:noreply,
            push_navigate(socket, to: "/data/#{dest_id}")
        }
    end
end
