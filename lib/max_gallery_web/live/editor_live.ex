defmodule MaxGalleryWeb.Live.EditorLive do
  ## Module for the site's editor field.
  use MaxGalleryWeb, :live_view
  alias MaxGallery.Context
  alias MaxGallery.Extension
  alias MaxGallery.Validate

  def mount(%{"id" => id} = params, %{"auth_key" => key, "user_auth" => user}, socket) do
    id = Validate.int!(id)
    page_id = Map.get(params, "page_id")

    {:ok, lazy_data} = Context.decrypt_one(user, id, key, lazy: true)

    ext =
      Map.fetch!(lazy_data, :ext)
      |> Extension.get_ext()

    ## If the type is not text, it only allows editing its name (enters lazy mode).
    lazy? =
      if ext == "text" do
        nil
      else
        true
      end

    {:ok, querry} = Context.decrypt_one(user, id, key, lazy: lazy?)

    socket =
      assign(socket,
        user: user,
        key: key,
        data: querry,
        id: id,
        page_id: page_id,
        edit_iframe: false,
        new_content: false
      )

    {:ok, socket, layout: false}
  end

  def mount(_params, _session, socket) do
    {:ok, push_navigate(socket, to: "/user/data")}
  end

  def handle_event("ask_edit", _params, socket) do
    {:noreply, assign(socket, edit_iframe: true)}
  end

  def handle_event("cancel_edit", _params, socket) do
    {:noreply, assign(socket, edit_iframe: false)}
  end

  def handle_event("redirect_edit", _params, socket) do
    page_id = socket.assigns[:page_id]

    {:noreply, push_navigate(socket, to: "/user/data/#{page_id}")}
  end

  def handle_event("confirm_edit", %{"new_content" => content, "new_name" => name}, socket) do
    id =
      socket.assigns[:id]
      |> Validate.int!()

    user = socket.assigns[:user]
    key = socket.assigns[:key]
    page_id = socket.assigns[:page_id]

    Context.cypher_update(user, id, %{name: name, blob: content}, key)
    {:noreply, push_navigate(socket, to: "/user/data/#{page_id}")}
  end

  def handle_event("confirm_edit", %{"new_name" => name}, socket) do
    id = socket.assigns[:id]
    user = socket.assigns[:user]
    key = socket.assigns[:key]
    page_id = socket.assigns[:page_id]

    Context.cypher_update(user, id, %{name: name}, key)
    {:noreply, push_navigate(socket, to: "/user/data/#{page_id}")}
  end

  def handle_event("update_content", %{"new_content" => content}, socket) do
    {:noreply, assign(socket, new_content: content)}
  end

  def handle_event("update_content", _params, socket) do
    {:noreply, socket}
  end
end
