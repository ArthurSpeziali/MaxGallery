defmodule MaxGalleryWeb.Live.ImportLive do
  ## Module for site's import files page.
  use MaxGalleryWeb, :live_view
  alias MaxGallery.Context
  alias MaxGallery.Utils
  alias MaxGallery.Variables

  def mount(params, %{"auth_key" => key, "user_auth" => user}, socket) do
    group_id = Map.get(params, "page_id")
    
    # Calculate current user storage
    current_size_gb = Utils.user_size(user)
    max_size_gb = Variables.max_size_user()
    storage_exceeded = current_size_gb >= max_size_gb

    zip? = Map.get(params, "zip")

    limit =
      if zip? do
        1
      else
        Variables.file_limit()
      end

    accepts =
      if zip? do
        ~w(.zip)
      else
        :any
      end

    socket =
      allow_upload(
        socket,
        :file_import,
        accept: accepts,
        max_entries: limit,
        max_file_size: Variables.file_size()
      )
      |> assign(
        key: key,
        user: user,
        loading: false,
        zip: zip?,
        page_id: group_id,
        current_size_gb: current_size_gb,
        max_size_gb: max_size_gb,
        storage_exceeded: storage_exceeded
      )

    {:ok, socket, layout: false}
  end

  def mount(_params, _session, socket) do
    push_navigate(socket, to: "/user/data")
  end

  ## Function for display file's name in the web.
  def name_files(uploads, zip?) do
    entries = uploads.file_import.entries

    case {entries, zip?} do
      {[], nil} ->
        "No files select."

      {[], _zip} ->
        "No files \".zip\" select."

      _entry ->
        Enum.map_join(entries, ", ", fn item ->
          "\"#{item.client_name}\""
        end)
    end
  end

  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("upload", _params, socket) do
    key = socket.assigns[:key]
    group_id = socket.assigns[:page_id]
    zip? = socket.assigns[:zip]
    user = socket.assigns[:user]
    storage_exceeded = socket.assigns[:storage_exceeded]

    if storage_exceeded do
      # Don't upload if storage limit is exceeded
      {:noreply, socket}
    else
      consume_uploaded_entries(socket, :file_import, fn %{path: path}, %{client_name: name} ->
        if zip? do
          if Utils.zip_valid?(path) do
            Context.unzip_content(path, user, key, group: group_id)
          else
            File.rm!(path)
          end
        else
          case Context.cypher_insert(path, user, key, name: name, group: group_id) do
            {:ok, _id} -> :ok
            {:error, "storage_limit_exceeded"} -> :storage_limit_exceeded
            {:error, _reason} -> :error
          end
        end

        {:ok, nil}
      end)

      {:noreply, push_navigate(socket, to: "/user/data/#{group_id}")}
    end
  end

  def handle_event("cancel", _params, socket) do
    page_id = socket.assigns[:page_id]

    socket = assign(socket, loading: false)
    {:noreply, push_navigate(socket, to: "/user/data/#{page_id}")}
  end

  def handle_event("loading", _params, socket) do
    {:noreply, assign(socket, loading: true)}
  end
end
