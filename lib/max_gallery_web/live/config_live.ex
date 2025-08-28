defmodule MaxGalleryWeb.Live.ConfigLive do
  ## Module for the site's settings page.
  use MaxGalleryWeb, :live_view
  alias MaxGallery.Phantom
  alias MaxGallery.Validate
  alias MaxGallery.Context

  def mount(_params, %{"user_auth" => user_id}, socket) do
    socket =
      assign(socket,
        changekey_iframe: nil,
        dropdata_iframe: nil,
        loading: nil,
        changepasswd_iframe: nil,
        deleteaccount_iframe: nil,
        err: nil,
        user_id: user_id
      )

    {:ok, socket, layout: false}
  end

  def mount(_params, _session, socket) do
    {:ok, push_navigate(socket, to: "/")}
  end

  def handle_event("redirect", _params, socket) do
    {:noreply, push_navigate(socket, to: "/user/data")}
  end

  def handle_event("cancel", _params, socket) do
    socket =
      assign(socket,
        changekey_iframe: nil,
        dropdata_iframe: nil,
        loading: nil,
        changepasswd_iframe: nil,
        deleteaccount_iframe: nil,
        err: nil
      )

    {:noreply, socket}
  end

  def handle_event("drop_data", _params, socket) do
    {:noreply, assign(socket, dropdata_iframe: true)}
  end

  def handle_event("submit_dropdata", %{"key" => key}, socket) do
    user = socket.assigns[:user_id]
    Context.delete_all(user, key)

    {:noreply, push_navigate(socket, to: "/user/data")}
  end

  def handle_event("change_key", _params, socket) do
    {:noreply, assign(socket, changekey_iframe: true)}
  end

  def handle_event("submit_changekey", %{"new_key" => _new_key, "old_key" => key}, socket) do
    user = socket.assigns[:user_id]

    if Phantom.insert_line?(user, key) do
      # Context.update_all(user, key, new_key) # Function is commented out in context.ex
    end

    {:noreply, push_navigate(socket, to: "/user/data")}
  end

  def handle_event("loading", _params, socket) do
    {:noreply, assign(socket, loading: true)}
  end

  ## User Config 
  def handle_event("logout", _params, socket) do
    {:noreply, push_navigate(socket, to: "/user/logout-user")}
  end

  def handle_event("change_passwd", _params, socket) do
    {:noreply, assign(socket, changepasswd_iframe: true)}
  end

  def handle_event(
        "submit_changepasswd",
        %{"new_passwd" => new_passwd, "old_passwd" => passwd},
        socket
      ) do
    {:ok, user} =
      socket.assigns.user_id
      |> Context.user_get()

    email = user.email

    match = {
      Context.user_validate(email, passwd |> Validate.input!()),
      Validate.passwd(new_passwd |> Validate.input!())
    }

    ok =
      case match do
        {{:ok, _id}, :ok} ->
          Context.user_update(email, %{password: new_passwd})
          :ok

        {{:error, _}, _} ->
          "Incorrect password. Try another one."

        {{:ok, _id}, {:error, reason}} ->
          "New password error: " <> reason
      end

    if ok == :ok do
      {:noreply, push_navigate(socket, to: "/user/data")}
    else
      {:noreply, assign(socket, err: ok)}
    end
  end

  def handle_event("delete_account", _params, socket) do
    {:noreply, assign(socket, deleteaccount_iframe: true)}
  end

  def handle_event("submit_deleteaccount", %{"passwd" => passwd}, socket) do
    {:ok, user} =
      socket.assigns.user_id
      |> Context.user_get()

    email = user.email

    ok =
      case Context.user_validate(email, passwd) do
        {:ok, _id} ->
          Context.user_delete(user.id)
          :ok

        {:error, _reason} ->
          "Invalid password. Try another one."
      end

    if ok == :ok do
      {:noreply, push_navigate(socket, to: "/user/logout-user")}
    else
      {:noreply, assign(socket, err: ok)}
    end
  end
end
