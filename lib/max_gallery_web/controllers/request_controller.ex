defmodule MaxGalleryWeb.RequestController do
    use MaxGalleryWeb, :controller


    def auth(conn, %{"key" => key}) do
        put_session(conn, :auth_key, key)
        |> redirect(to: "/user/data")
    end
    def auth(conn, _params) do
        redirect(conn, to: "/user")
    end

    def auth_user(conn, %{"id" => id}) do
        put_session(conn, :auth_user, id)
        |> configure_session(renew: true)
    end
    def auth_user(conn, _params) do
        redirect(conn, to: "/")
    end

    def email_forget(conn, %{"email" => _email}) do
        redirect(conn, to: "/check")
    end
end
