defmodule MaxGalleryWeb.PageController do
    use MaxGalleryWeb, :controller
    alias MaxGallery.Server.LiveServer
    alias MaxGallery.Context


    def home(conn, _params) do
        # The home page is often custom made,
        # so skip the default app layout.
        render(conn, :home, layout: false)
    end

    def auth(conn, %{"key" => key}) do
        put_session(conn, :auth_key, key)
        |> redirect(to: "/data")
    end
    def auth(conn, _params) do
        redirect(conn, to: "/")
    end

    def logout(conn, _params) do
        LiveServer.clr()
            
        configure_session(conn, drop: true)
        |> redirect(to: "/")
    end

    def images(conn, %{"id" => id}) do
        key = LiveServer.get(:auth_key)
        {:ok, querry} = Context.decrypt_one(id, key) 

        put_resp_content_type(conn, "image/png")
        |> send_resp(200, querry.blob)
    end
end
