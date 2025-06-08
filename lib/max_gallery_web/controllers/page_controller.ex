defmodule MaxGalleryWeb.PageController do
    use MaxGalleryWeb, :controller
    alias MaxGallery.Server.LiveServer
    alias MaxGallery.Extension
    alias MaxGallery.Context
    alias MaxGallery.Utils


    defp content_render(conn, id) do
        key = get_session(conn, :auth_key)
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
        key = get_session(conn, :auth_key)

        case Context.decrypt_one(id, key) do
            {:ok, %{blob: blob, ext: ext}} ->
                mime = Extension.get_mime(ext)

                conn = put_resp_content_type(conn, mime)
                       |> put_resp_header("accept-ranges", "bytes")
                       |> send_chunked(200)


                Utils.binary_chunk(blob, 128 * 1024) # 128KB
                |> Enum.reduce_while(conn, fn blob_chunk, conn -> 
    
                    case chunk(conn, blob_chunk) do
                        {:ok, conn} -> {:cont, conn}
                        {:error, _reason} -> {:halt, conn}
                    end
                end)

            error -> error
        end
    end

    def audios(conn, %{"id" => id}) do
        content_render(conn, id)
    end


    def download(conn, %{"id" => id, "type" => "group"}) do
        key = get_session(conn, :auth_key)

        if key do
            {:ok, file_path} = Context.zip_content(id, key, group: true)

            send_download(conn, {:file, file_path})
        else
            redirect(conn, to: ~c"/")
        end
    end
    def download(conn, %{"id" => id, "type" => "data"}) do
        key = get_session(conn, :auth_key)

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

end
