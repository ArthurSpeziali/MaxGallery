defmodule MaxGalleryWeb.RequestController do
  use MaxGalleryWeb, :controller
  alias MaxGalleryWeb.Endpoint
  alias MaxGallery.Variables
  alias MaxGallery.Utils
  alias MaxGallery.Mail.Template
  alias MaxGallery.Mail.Email

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

  def email_forget(conn, %{"email" => email}) do
    user_request = conn.assigns[:timestamp_request]

    if user_request do
      now = DateTime.utc_now()

      valid? =
        DateTime.after?(
          DateTime.add(user_request.timestamp, Variables.email_resend(), :second),
          now
        )

      if valid? do
        email_forget_process(conn, email)
      else
        remain = DateTime.diff(now, user_request.timestamp, :second)
        redirect(conn, to: "/forget?remain=#{remain}")
      end
    else
      email_forget_process(conn, email)
    end
  end

  def email_forget(conn, _params) do
    redirect(conn, to: "/")
  end

  def email_forget_process(conn, email) do
    host =
      Application.get_env(:max_gallery, MaxGalleryWeb.Endpoint)[:url]
      |> Keyword.get(:host)

    token = Utils.enc_timestamp(email)

    link =
      "https://" <> host <> "/reset-passwd?token=#{token}"

    Template.reset_passwd(email, link)
    |> Email.send()

    conn = assign(conn, :timestamp_request, %{timestamp: DateTime.utc_now(), email: email})
    redirect(conn, to: "/forget?send=true")
  end
end
