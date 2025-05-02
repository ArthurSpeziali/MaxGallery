defmodule MaxGalleryWeb.MoveLive do
    use MaxGalleryWeb, :live_view
    alias MaxGallery.Context
    alias MaxGallery.Server.LiveServer
    alias MaxGallery.Utils


    def mount(%{"action" => action} = params, _session, socket) do
        object = LiveServer.get(:object_info)
        page_id = Map.get(params, "id")
        key = LiveServer.get(:auth_key)

        if object do
            {:ok, group_info} = 
                if page_id do 
                    Context.decrypt_one(page_id, key, group: true)
                else
                    {:ok, %{name: "Main"}}
                end 

            {:ok, raw_groups} = Context.decrypt_all(key, only: :groups, group: page_id) 

            groups = 
                if object.type == "group" do
                    {:ok, content} = Context.decrypt_one(
                        object.id,
                        key,
                        group: true
                    ) 
                    int_content = Map.update!(
                        content,
                        :id,
                        fn item ->
                            String.to_integer(item)
                        end
                    )

                    raw_groups -- [int_content] 
                end 

            socket = assign(socket,
                group_name: group_info[:name],
                page_id: page_id,
                groups: groups,
                action: action
            )

            {:ok, socket, layout: false}
        else
            {:ok,
                push_navigate(socket, to: "/data/#{page_id}")
            }
        end
    end
    def mount(_params, _session, socket) do
        {:ok,
            push_navigate(socket, to: "/data")
        }
    end


    def handle_event("open", %{"id" => id}, socket) do
        action = socket.assigns[:action]

        {:noreply,
            push_navigate(socket, to: "/move/#{id}?action=#{action}")
        }
    end

    def handle_event("back", _params, socket) do
        action = socket.assigns[:action]
        back_id = socket.assigns[:page_id]
                  |> Utils.get_back()
                  
        {:noreply, 
            push_navigate(socket, to: "/move/#{back_id}?action=#{action}")
        }
    end

    def handle_event("select", %{"id" => dest_id}, socket) do
        key = LiveServer.get(:auth_key)
        object = LiveServer.get(:object_info)
        action = socket.assigns[:action]

        dest_id = 
            if dest_id == "main" do
                nil
            else
                dest_id
            end

        case {object.type, action} do
            {"data", "move"} ->
                Context.cypher_update(object.id, %{group_id: dest_id}, key)


            {"group", "move"} ->
                Context.group_update(object.id, %{group_id: dest_id}, key)


            {"data", "copy"} ->
                params = 
                    if dest_id do 
                        %{group_id: String.to_integer(dest_id)}
                    else
                        %{group_id: nil}
                    end
                Context.cypher_duplicate(object.id, params, key)


            {"group", "copy"} ->
                insert_content = fn
                    (content, :data) ->
                        MaxGallery.Core.Data.Api.insert(content)

                    (content, :group) ->
                        {:ok, querry} = MaxGallery.Core.Group.Api.insert(content)
                        %{group_id: querry.id}
                end

                params = 
                    if dest_id do 
                        %{group_id: String.to_integer(dest_id)}
                    else
                        %{group_id: nil}
                    end


                {:ok, group_id} = Context.group_duplicate(object.id, params, key)

                Utils.get_tree(object.id, key)
                |> Utils.mount_tree(
                    %{group_id: group_id}, 
                    insert_content, 
                    key
                )
        end


        {:noreply,
            push_navigate(socket, to: "/data/#{dest_id}")
        }
    end
end
