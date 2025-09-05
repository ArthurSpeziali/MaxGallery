defmodule MaxGalleryWeb.Live.DataLive do
  ## Module for the site's main page.
  use MaxGalleryWeb, :live_view
  alias MaxGallery.Context
  alias MaxGallery.Extension
  alias MaxGallery.Utils
  alias MaxGallery.Variables
  alias MaxGallery.Validate

  def mount(params, %{"auth_key" => key, "user_auth" => user}, socket) do
    group_id = Map.get(params, "page_id")

    {:ok, lazy_datas} = Context.decrypt_all(user, key, lazy: true, group: group_id)

    socket =
      assign(socket,
        user: user,
        key: key,
        datas: lazy_datas,
        lock_datas: lazy_datas,
        page_id: group_id,
        delete_iframe: nil,
        rename_iframe: nil,
        remove_iframe: nil,
        more_iframe: nil,
        info_iframe: nil,
        create_iframe: nil
      )

    {:ok, socket, layout: false}
  end

  def mount(_params, _session, socket) do
    {:ok, push_navigate(socket, to: "/user")}
  end

  def handle_event("ask_delete", %{"id" => id, "name" => name}, socket) do
    {:noreply, assign(socket, delete_iframe: id, name_data: name)}
  end

  def handle_event("cancel", _params, socket) do
    socket =
      assign(socket,
        delete_iframe: nil,
        rename_iframe: nil,
        remove_iframe: nil,
        more_iframe: nil,
        info_iframe: nil,
        create_iframe: nil
      )

    {:noreply, socket}
  end

  def handle_event("confirm_delete", %{"id" => id}, socket) do
    user = socket.assigns[:user]
    key = socket.assigns[:key]
    page_id = socket.assigns[:page_id]

    Context.cypher_delete(user, id, key)

    {:noreply, push_navigate(socket, to: "/user/data/#{page_id}")}
  end

  def handle_event("editor", %{"id" => id}, socket) do
    page_id = socket.assigns[:page_id]

    {:noreply, push_navigate(socket, to: "/user/editor/#{page_id}?id=#{id}")}
  end

  def handle_event("show", %{"id" => id}, socket) do
    page_id = socket.assigns[:page_id]

    {:noreply, push_navigate(socket, to: "/user/show/#{page_id}?id=#{id}")}
  end

  def handle_event("import_file", _params, socket) do
    page_id = socket.assigns[:page_id]

    {:noreply, push_navigate(socket, to: "/user/import/#{page_id}")}
  end

  def handle_event("ask_rename", %{"id" => id, "name" => name}, socket) do
    socket =
      assign(socket,
        rename_iframe: id,
        name_group: name
      )

    {:noreply, socket}
  end

  def handle_event("confirm_rename", %{"id" => id, "new_name" => name}, socket) do
    user = socket.assigns[:user]
    key = socket.assigns[:key]
    page_id = socket.assigns[:page_id]
    Context.group_update(user, id, %{name: name}, key)

    {:noreply, push_navigate(socket, to: "/user/data/#{page_id}")}
  end

  def handle_event("ask_remove", %{"id" => id, "name" => name}, socket) do
    socket =
      assign(socket,
        remove_iframe: id,
        name_group: name
      )

    {:noreply, socket}
  end

  def handle_event("confirm_remove", %{"id" => id}, socket) do
    id = Validate.int!(id)
    user = socket.assigns[:user]
    key = socket.assigns[:key]
    page_id = socket.assigns[:page_id]
    Context.group_delete(user, id, key)

    {:noreply, push_navigate(socket, to: "/user/data/#{page_id}")}
  end

  def handle_event("redirect", _params, socket) do
    page_id = socket.assigns[:page_id]

    {:noreply, push_navigate(socket, to: "/user/data/#{page_id}")}
  end

  def handle_event("open", %{"id" => id}, socket) do
    {:noreply, push_navigate(socket, to: "/user/data/#{id}")}
  end

  def handle_event("back", _params, socket) do
    back_id =
      socket.assigns[:page_id]
      |> Utils.get_back()

    {:noreply, push_navigate(socket, to: "/user/data/#{back_id}")}
  end

  def handle_event("ask_folder", _params, socket) do
    socket =
      assign(socket,
        ## Reuses the same variable to create groups.
        rename_iframe: :create,
        name_group: ""
      )

    {:noreply, socket}
  end

  def handle_event("confirm_folder", %{"new_name" => name}, socket) do
    user = socket.assigns[:user]
    key = socket.assigns[:key]
    page_id = socket.assigns[:page_id]
    Context.group_insert(name, user, key, group: page_id)

    {:noreply, push_navigate(socket, to: "/user/data/#{page_id}")}
  end

  def handle_event("more_menu", %{"id" => id, "type" => type}, socket) do
    {:noreply, assign(socket, more_iframe: id, type: type)}
  end

  def handle_event("move", %{"id" => id}, socket) do
    page_id = socket.assigns[:page_id]
    type = socket.assigns[:type]

    {:noreply,
     push_navigate(socket, to: "/user/move/#{page_id}?action=move&id=#{id}&type=#{type}")}
  end

  def handle_event("copy", %{"id" => id}, socket) do
    page_id = socket.assigns[:page_id]
    type = socket.assigns[:type]

    {:noreply,
     push_navigate(socket, to: "/user/move/#{page_id}?action=copy&id=#{id}&type=#{type}")}
  end

  def handle_event("info", %{"id" => id}, socket) do
    user = socket.assigns[:user]
    key = socket.assigns[:key]
    type = socket.assigns[:type]

    group? =
      if type == "group" do
        true
      else
        nil
      end

    {:ok, object} = Context.decrypt_one(user, id, key, group: group?, lazy: true)

    size =
      Utils.get_size(user, id, group: group?)
      |> Extension.convert_size()

    group_name =
      if object.group do
        {:ok, querry} = Context.decrypt_one(user, object.group, key, group: true)
        Map.fetch!(querry, :name)
      else
        "Main"
      end

    ## Adjusts the NaiveDateTime to be displayed on the web.
    %{inserted_at: inserted_at, updated_at: updated_at} = Utils.get_timestamps(id, group: group?)

    timestamps = %{
      inserted_at: NaiveDateTime.to_string(inserted_at),
      updated_at: NaiveDateTime.to_string(updated_at)
    }

    socket =
      assign(socket,
        info_iframe: true,
        more_iframe: nil,
        object: object,
        size: size,
        group_name: group_name,
        timestamps: timestamps
      )

    {:noreply, socket}
  end

  def handle_event("search", %{"search" => search}, socket) do
    querry =
      socket.assigns[:lock_datas]
      |> Utils.get_like(search)

    {:noreply, assign(socket, datas: querry)}
  end

  def handle_event("ask_file", _params, socket) do
    {:noreply, assign(socket, create_iframe: true)}
  end

  def handle_event("confirm_createfile", %{"name" => name}, socket) do
    user = socket.assigns[:user]
    key = socket.assigns[:key]
    group = socket.assigns[:page_id]

    group =
      if group do
        Variables.int!(group)
      else
        group
      end

    path = Variables.tmp_dir() <> "tests/#{user}_sys_#{Enum.random(1..999//1)}"
    File.mkdir_p(Variables.tmp_dir() <> "tests/")
    File.write(path, "", [:write])

    Context.cypher_insert(path, user, key, name: name, group: group)
    {:noreply, push_navigate(socket, to: "/user/data/#{group}")}
  end

  def handle_event("import_folder", _params, socket) do
    page_id = socket.assigns[:page_id]

    {:noreply, push_navigate(socket, to: "/user/import/#{page_id}?zip=true")}
  end
end
