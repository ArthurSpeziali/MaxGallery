defmodule MaxGalleryWeb.PageController do
    use MaxGalleryWeb, :controller
    alias MaxGallery.Server.LiveServer


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
end
