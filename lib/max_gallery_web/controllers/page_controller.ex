defmodule MaxGalleryWeb.PageController do
    use MaxGalleryWeb, :controller
    alias MaxGallery.Server.LiveServer
    alias MaxGallery.Variables


    ## Remove assings, cookies, files, etc...
    def logout(conn, _params) do
        LiveServer.clr()
        File.rm_rf!(Variables.tmp_dir)

        configure_session(conn, drop: true)
        |> redirect(to: "/user")
    end


    def home(conn, _params) do
        render(conn, :home, layout: false)
    end

    def not_found(conn, _params) do
        put_status(conn, 404)
        |> render(:error, layout: false)
    end

    def landing(conn, _params) do
        render(conn, :landing, layout: false, hide_header: true)
    end

    def login(conn, _params) do
        render(conn, :login, layout: false, hide_header: true)
    end

    def forget(conn, _params) do
        render(conn, :forget, layout: false, hide_header: true)
    end

    def register(conn, _params) do
        render(conn, :register, layout: false, hide_header: true)
    end

    def check(conn, _params) do
        render(conn, :check, layout: false, hide_header: true)
    end
end
