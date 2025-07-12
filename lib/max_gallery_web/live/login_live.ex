defmodule MaxGalleryWeb.Live.LoginLive do
  use MaxGalleryWeb, :live_view
  alias MaxGallery.Validate
  alias MaxGallery.Context
  alias MaxGalleryWeb.Endpoint
  alias MaxGallery.UserValidation

  def mount(%{"action" => action}, _session, socket) do
    action =
      if action in ~w(login register) do
        action
      else
        "login"
      end

    counter =
      if action == "login" do
        "register"
      else
        "login"
      end

    socket =
      assign(socket,
        action: action,
        counter: counter,
        error_list: [],
        hide_header: true
      )

    {:ok, socket, layout: false}
  end

  def mount(_params, _session, socket) do
    {:ok, push_navigate(socket, to: "/")}
  end

  def handle_event("confirm_form", %{"action" => "login"} = params, socket) do
    error_list = []

    %{"email" => email, "passwd" => password} = params

    {femail, fpassword} = {
      Validate.input!(email),
      Validate.input!(password)
    }

    error_list =
      case Validate.email(femail) do
        :ok -> error_list
        {:error, reason} -> [err_email: reason] ++ error_list
      end

    error_list =
      case Validate.passwd(fpassword) do
        :ok -> error_list
        {:error, reason} -> [err_passwd: reason] ++ error_list
      end

    response =
      if error_list == [] do
        case Context.user_validate(femail, fpassword) do
          {:error, "invalid email/passwd"} ->
            {:error,
             [err_get: "Password or E-mail is invalid. Try another credentials."] ++ error_list}

          {:error, "not found"} ->
            {:error, [err_get: "This User does not exist in our database."] ++ error_list}

          id ->
            id
        end
      else
        {:error, error_list}
      end

    case response do
      {:ok, id} ->
        sign_id = Phoenix.Token.sign(Endpoint, "auth_user", id)
        {:noreply, push_navigate(socket, to: "/request/auth-user?token=#{sign_id}")}

      {:error, error_list} ->
        {:noreply, assign(socket, error_list: error_list)}
    end
  end

  def handle_event("confirm_form", %{"action" => "register"} = params, socket) do
    error_list = []

    %{"name" => name, "email" => email, "passwd" => password} = params

    {fname, femail, fpassword} = {
      String.trim(name),
      Validate.input!(email),
      Validate.input!(password)
    }

    error_list =
      case Validate.name(fname) do
        :ok -> error_list
        {:error, reason} -> [err_name: reason] ++ error_list
      end

    error_list =
      case Validate.email(femail) do
        :ok -> error_list
        {:error, reason} -> [err_email: reason] ++ error_list
      end

    error_list =
      if Validate.email?(femail) do
        error_list
      else
        [err_email: "This E-mail alredy been taken."] ++ error_list
      end

    error_list =
      case Validate.passwd(fpassword) do
        :ok -> error_list
        {:error, reason} -> [err_passwd: reason] ++ error_list
      end

    if error_list == [] do
      user_object = %UserValidation{
        name: fname,
        email: femail,
        password: fpassword
      }

      token = Phoenix.Token.sign(Endpoint, "email_check", user_object)
      {:noreply, push_navigate(socket, to: "/request/email-check?token=#{token}")}
    else
      {:noreply, assign(socket, error_list: error_list)}
    end
  end
end
