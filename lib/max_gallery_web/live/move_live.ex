defmodule MaxGalleryWeb.Live.MoveLive do
  ## Module for the site's moving and copying action in the page.
  use MaxGalleryWeb, :live_view
  alias MaxGallery.Context
  alias MaxGallery.Validate
  alias MaxGallery.Utils

  def mount(
        %{"action" => action, "id" => id, "type" => type} = params,
        %{"auth_key" => key, "user_auth" => user},
        socket
      ) do
    page_id = Map.get(params, "page_id")

    page_id =
      if page_id == "main" do
        nil
      else
        page_id
      end

    id = Validate.int!(id)

    action =
      if action in ~w(move copy) do
        action
      else
        "move"
      end

    {:ok, group_info} =
      if page_id do
        Context.decrypt_one(user, page_id, key, group: true)
      else
        {:ok, %{name: "Main"}}
      end

    {:ok, raw_groups} = Context.decrypt_all(user, key, only: :groups, group: page_id)

    groups =
      if type == "group" do
        {:ok, content} =
          Context.decrypt_one(
            user,
            id,
            key,
            group: true
          )

        ## Removes itself from the list (if it's a group) to avoid infinite recursion.
        raw_groups -- [content]
      else
        raw_groups
      end

    socket =
      assign(socket,
        user: user,
        key: key,
        group_name: group_info[:name],
        page_id: page_id,
        groups: groups,
        action: action,
        type: type,
        id: id,
        loading: nil
      )

    {:ok, socket, layout: false}
  end

  def mount(_params, _session, socket) do
    {:ok, push_navigate(socket, to: "/user/data")}
  end

  def handle_event("open", %{"id" => new_id}, socket) do
    action = socket.assigns[:action]
    type = socket.assigns[:type]
    id = socket.assigns[:id]

    {:noreply,
     push_navigate(socket, to: "/user/move/#{new_id}?action=#{action}&type=#{type}&id=#{id}")}
  end

  def handle_event("back", _params, socket) do
    action = socket.assigns[:action]
    type = socket.assigns[:type]
    id = socket.assigns[:id]

    back_id =
      (socket.assigns[:page_id] |> Utils.get_back())
      || "main"

    ## This is only time that `Utils.get_back/1` is called. Should i delete this function?

    {:noreply,
     push_navigate(socket, to: "/user/move/#{back_id}?action=#{action}&type=#{type}&id=#{id}")}
  end

  def handle_event("select", %{"id" => dest_id}, socket) do
    user = socket.assigns[:user]
    key = socket.assigns[:key]

    id =
      socket.assigns[:id]
      |> Validate.int!()

    type = socket.assigns[:type]
    action = socket.assigns[:action]

    dest_id =
      if dest_id == "main" do
        nil
      else
        Validate.int!(dest_id)
      end

    case {type, action} do
      {"data", "move"} ->
        Context.cypher_update(user, id, %{group_id: dest_id}, key)

      {"group", "move"} ->
        Context.group_update(user, id, %{group_id: dest_id}, key)

      {"data", "copy"} ->
        params =
          if dest_id do
            %{group_id: dest_id}
          else
            %{group_id: nil}
          end

        Context.cypher_duplicate(user, id, params, key)

      {"group", "copy"} ->
        params =
          if dest_id do
            %{group_id: dest_id}
          else
            %{group_id: nil}
          end

        Context.group_duplicate(user, id, params, key)
    end

    {:noreply, push_navigate(socket, to: "/user/data/#{dest_id}")}
  end

  def handle_event("loading", _params, socket) do
    {:noreply, assign(socket, loading: true)}
  end
end
