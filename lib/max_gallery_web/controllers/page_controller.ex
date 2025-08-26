defmodule MaxGalleryWeb.PageController do
  use MaxGalleryWeb, :controller
  alias MaxGallery.Variables
  alias MaxGallery.Context
  alias MaxGallery.Validate
  alias MaxGallery.Utils
  alias MaxGallery.Mail.Template
  alias MaxGallery.Mail.Email

  ## Remove assings, cookies, files, etc...
  def logout(conn, _params) do
    File.rm_rf(Variables.tmp_dir())

    configure_session(conn, drop: true)
    |> redirect(to: "/user")
  end

  def logout_user(conn, _params) do
    File.rm_rf(Variables.tmp_dir())

    configure_session(conn, drop: true)
    |> delete_resp_cookie("auth_user")
    |> redirect(to: "/")
  end

  def home(conn, _params) do
    # Corrigido: forma correta de ler cookie assinado
    conn = fetch_cookies(conn, signed: ["auth_user"])
    id = conn.cookies["auth_user"]

    if id do
      put_session(conn, "user_auth", id)
      |> render(:home, layout: false)
    else
      redirect(conn, to: "/login?action=login")
    end
  end

  def not_found(conn, _params) do
    put_status(conn, 404)
    |> render(:error, layout: false)
  end

  def landing(conn, _params) do
    render(conn, :landing, layout: false, hide_header: nil)
  end

  def verify(conn, _params) do
    user = get_session(conn, :user_validation)

    if user do
      Template.email_verify(user.email, user.code)
      |> Email.send()

      render(conn, :verify, layout: false, hide_header: true, email: user.email, err_code: nil)
    else
      redirect(conn, to: "/")
    end
  end

  def verify_process(conn, %{"place_code" => place_code}) do
    user = get_session(conn, :user_validation)

    if user do
      if user.code == place_code do
        user = %{user | verify?: true}

        {:ok, id} =
          Context.user_insert(
            user.name,
            user.email,
            user.password
          )

        put_session(conn, :user_validation, user)

        put_resp_cookie(conn, "auth_user", id, sign: true, max_age: Variables.cookie_time())
        |> redirect(to: "/user")
      else
        render(conn, :verify,
          layout: false,
          hide_header: true,
          email: user.email,
          err_code: "Invalid code. Try again."
        )
      end
    else
      redirect(conn, to: "/")
    end
  end

  def verify_process(conn, _params) do
    redirect(conn, to: "/")
  end

  def forget(conn, params) do
    {txt, send?} =
      cond do
        params["send"] ->
          {"Your e-mail has just been sent.", true}

        params["remain"] ->
          {params["remain"], :wait}

        params["invalid"] ->
          {"This e-mail does not exists in our database.", false}

        true ->
          {nil, false}
      end

    render(conn, :forget, layout: false, hide_header: true, txt: txt, send: send?)
  end

  def reset(conn, %{"token" => token}) do
    case Utils.dec_timestamp(token) do
      {:error, _reason} ->
        redirect(conn, to: "/")

      {timestamp, email} ->
        expired? =
          DateTime.after?(
            DateTime.utc_now(),
            DateTime.add(timestamp, Variables.reset_time(), :minute)
          )

        if expired? do
          redirect(conn, to: "/")
        else
          render(conn, :reset, layout: false, hide_header: true, email: email, err: nil)
        end
    end
  end

  def reset(conn, _params) do
    email = "noone@nohost.no"
    render(conn, :reset, layout: false, hide_header: true, email: email, err: nil)
    # redirect(conn, to: "/user")
  end

  def reset_process(conn, %{"email" => email, "new_passwd" => password}) do
    case Validate.passwd(password) do
      {:error, reason} ->
        render(conn, :reset, layout: false, hide_header: true, email: email, err: reason)

      :ok ->
        Context.user_update(email, %{password: password})

        redirect(conn, to: "/login?action=login")
    end
  end

  def reset_process(conn, _params) do
    redirect(conn, to: "/")
  end
end
