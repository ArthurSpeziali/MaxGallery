defmodule MaxGalleryWeb.RequestController do
  use MaxGalleryWeb, :controller
  alias MaxGalleryWeb.Endpoint
  alias MaxGallery.Variables
  alias MaxGallery.Utils
  alias MaxGallery.Mail.Template
  alias MaxGallery.Mailout
  alias MaxGallery.Context
  alias MaxGallery.Server.LiveServer

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
    case Context.user_get(nil, email: email) do
      {:error, _reason} ->
        redirect(conn, to: "/forget?invalid=true")

      {:ok, _id} ->
        # Store email in session for timestamp checking like in verify
        conn = put_session(conn, :forget_email, email)
        
        user_request = LiveServer.get(:timestamp_requests)[email]

        if user_request do
          remain =
            DateTime.diff(
              DateTime.utc_now(),
              user_request,
              :second
            )

          if remain >= Variables.email_resend() do
            email_forget_process(conn, email)
          else
            redirect(conn, to: "/forget")
          end
        else
          email_forget_process(conn, email)
        end
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

    task =
      Template.reset_passwd(email, link)
      |> Mailout.send()

    spawn(fn -> Mailout.response(task, email) end)

    LiveServer.add(:timestamp_requests, %{email => DateTime.utc_now()})

    redirect(conn, to: "/forget?send=true")
  end

end
