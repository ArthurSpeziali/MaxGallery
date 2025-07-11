defmodule MaxGalleryWeb.RequestController do
  use MaxGalleryWeb, :controller
  alias MaxGalleryWeb.Endpoint

  def auth(conn, %{"key" => key}) do
    put_session(conn, :auth_key, key)
    |> redirect(to: "/user/data")
  end

  def auth(conn, _params) do
    redirect(conn, to: "/user")
  end

  def auth_user(conn, %{"token" => token}) do
    MaxGallery.Server.LiveServer.put(%{conn: conn})

    case Phoenix.Token.verify(Endpoint, "auth_user", token) do
      {:ok, id} ->
        put_resp_cookie(conn, "auth_user", id, sign: true)
        |> redirect(to: "/user")

      {:error, _reason} ->
        redirect(conn, to: "/")
    end
  end

  def auth_user(conn, _params) do
    redirect(conn, to: "/")
  end

  def email_forget(conn, %{"email" => _email}) do
    redirect(conn, to: "/check")
  end
end
