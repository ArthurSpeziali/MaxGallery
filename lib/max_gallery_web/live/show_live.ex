defmodule MaxGalleryWeb.Live.ShowLive do
  ## Module for site's contents show page.
  use MaxGalleryWeb, :live_view
  alias MaxGallery.Context
  alias MaxGallery.Extension
  alias MaxGallery.Phantom
  alias MaxGallery.Validate

  def mount(%{"id" => id} = params, %{"auth_key" => key, "user_auth" => user}, socket) do
    page_id =
      Map.get(params, "page_id")

    page_id =
      if page_id do
        Validate.int!(page_id)
      else
        page_id
      end

    id = Validate.int!(id)

    {:ok, raw_querry} = Context.decrypt_one(user, id, key, lazy: true)

    lazy =
      if Extension.get_ext(raw_querry.ext) != "text" do
        true
      else
        nil
      end

    {:ok, querry} = Context.decrypt_one(user, id, key, lazy: lazy)

    encoded_data = Map.update!(querry, :name, fn item -> 
      Phantom.validate_bin(item) 
    end) 

    encoded_data = 
      if Phantom.insert_line?(user, key) do
          encoded_data
        else
          Map.update!(encoded_data, :blob, fn item -> 
            Phantom.validate_bin(item)
          end)
      end


    socket =
      assign(socket,
        data: encoded_data,
        page_id: page_id,
        id: id
      )

    {:ok, socket, layout: false}
  end

  def mount(_params, _session, socket) do
    {:ok, push_navigate(socket, to: "/user/data")}
  end

  def handle_event("cancel", _params, socket) do
    page_id = socket.assigns[:page_id]

    {:noreply, push_navigate(socket, to: "/user/data/#{page_id}")}
  end
end
