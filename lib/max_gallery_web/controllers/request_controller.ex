defmodule MaxGalleryWeb.RequestController do
  use MaxGalleryWeb, :controller
  alias MaxGalleryWeb.Endpoint
  alias MaxGallery.Variables
  alias MaxGallery.Utils

  def auth(conn, %{"key" => key}) do
    put_session(conn, :auth_key, key)
    |> redirect(to: "/user/data")
  end

  def auth(conn, _params) do
    redirect(conn, to: "/user")
  end

  def auth_user(conn, %{"token" => token}) do
    case Phoenix.Token.verify(Endpoint, "auth_user", token) do
      {:ok, id} ->
        put_resp_cookie(conn, "auth_user", id, sign: true, max_age: Variables.cookie_time())
        |> redirect(to: "/user")

      {:error, _reason} ->
        redirect(conn, to: "/")
    end
  end

  def auth_user(conn, _params) do
    redirect(conn, to: "/")
  end

  def email_check(conn, %{"token" => token}) do
    case Phoenix.Token.verify(Endpoint, "email_check", token) do
      {:ok, user} ->
        code =
          Variables.code_digits()
          |> Utils.gen_code()

        user = %{user | code: code}

        put_session(conn, :user_validation, user)
        |> redirect(to: "/email-verify")

      {:error, _reason} ->
        redirect(conn, to: "/")
    end
  end

  def email_check(conn, _params) do
    redirect(conn, to: "/")
  end
end
