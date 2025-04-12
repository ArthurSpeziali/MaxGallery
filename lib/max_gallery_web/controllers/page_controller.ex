defmodule MaxGalleryWeb.PageController do
    use MaxGalleryWeb, :controller
    alias MaxGallery.Server.LiveServer
    alias MaxGallery.Extension
    alias MaxGallery.Context


    defp content_render(conn, id) do
        key = LiveServer.get(:auth_key)
        {:ok, querry} = Context.decrypt_one(id, key) 

        mime = Map.fetch!(querry, :ext)
               |> Extension.get_mime()

        put_resp_content_type(conn, mime)
        |> send_resp(200, querry.blob)
    end


    def home(conn, _params) do
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
        content_render(conn, id)
    end

    def videos(conn, %{"id" => id}) do
        content_render(conn, id)
    end
end
