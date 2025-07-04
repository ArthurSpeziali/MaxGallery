defmodule MaxGalleryWeb.RequestController do
    use MaxGalleryWeb, :controller
    alias MaxGallery.Server.LiveServer
    


    def auth(conn, %{"key" => key}) do
        LiveServer.put(%{auth_key: key})

        put_session(conn, :auth_key, key)
        |> redirect(to: "/user/data")
    end
    def auth(conn, _params) do
        redirect(conn, to: "/user")
    end

    def email_forget(conn, %{"email" => _email}) do
        redirect(conn, to: "/check")
    end
end
