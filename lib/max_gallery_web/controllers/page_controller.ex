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

    def audios(conn, %{"id" => id}) do
        content_render(conn, id)
    end


    def download(conn, %{"id" => id, "type" => "group"}) do
        key = LiveServer.get(:auth_key)

        if key do
            {:ok, file_path} = Context.zip_content(id, key, group: true)

            send_download(conn, {:file, file_path})
        else
            redirect(conn, to: ~c"/")
        end
    end
    def download(conn, %{"id" => id, "type" => "data"}) do
        key = LiveServer.get(:auth_key)

        if key do
            {:ok, file_path} = Context.zip_content(id, key)

            send_download(conn, {:file, file_path})
        else
            redirect(conn, to: ~c"/")
        end
    end
    def download(conn, _params) do
        redirect(conn, to: "/data")
    end


    def config(conn, _params) do
        render(conn, :config, layout: false)
    end
end
