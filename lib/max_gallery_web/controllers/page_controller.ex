defmodule MaxGalleryWeb.PageController do
    use MaxGalleryWeb, :controller
    alias MaxGallery.Server.LiveServer
    alias MaxGallery.Extension
    alias MaxGallery.Context
    alias MaxGallery.Variables


    ## Decrypt the file and shows instantly.
    defp content_render(conn, id) do
        key = get_session(conn, :auth_key)
        {:ok, querry} = Context.decrypt_one(id, key) 

        mime = Map.fetch!(querry, :ext)
               |> Extension.get_mime()

        file = File.read(querry.path)
        case file do
            {:ok, cont} ->
                put_resp_content_type(conn, mime)
                |> send_resp(200, cont)

            {:error, :enoent} ->
                redirect(conn, to: "/user/data")
        end
    end


    def home(conn, _params) do
        render(conn, :home, layout: false)
    end

    def auth(conn, %{"key" => key}) do
        LiveServer.put(%{auth_key: key})

        put_session(conn, :auth_key, key)
        |> redirect(to: "/user/data")
    end
    def auth(conn, _params) do
        redirect(conn, to: "/user")
    end

    ## Remove assings, cookies, files, etc...
    def logout(conn, _params) do
        LiveServer.clr()
        File.rm_rf!(Variables.tmp_dir)

        configure_session(conn, drop: true)
        |> redirect(to: "/user")
    end


    def images(conn, %{"id" => id}) do
        content_render(conn, id)
    end


    ## Load the file, and chucked it. It's ensure the videos loads faster.
    def videos(conn, %{"id" => id}) do
        key = get_session(conn, :auth_key)
        {:ok, querry} = Context.decrypt_one(id, key)

        if File.exists?(querry.path) do 
            mime = Extension.get_mime(querry.ext)
            conn = put_resp_content_type(conn, mime)
                   |> put_resp_header("accept-ranges", "bytes")
                   |> send_chunked(200)


            File.stream!(querry.path, [], Variables.chunk_size)
            |> Enum.reduce_while(conn, fn blob_chunk, conn -> 
                case chunk(conn, blob_chunk) do
                    {:ok, conn} -> {:cont, conn}
                    {:error, _reason} -> {:halt, conn}
                end
            end)

        else
            redirect(conn, to: "/user/data")
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
            redirect(conn, to: "/user")
        end
    end
    def download(conn, %{"id" => id, "type" => "data"}) do
        key = get_session(conn, :auth_key)

        if key do
            {:ok, file_path} = Context.zip_content(id, key)

            send_download(conn, {:file, file_path})
        else
            redirect(conn, to: "/user")
        end
    end
    def download(conn, _params) do
        redirect(conn, to: "/user/data")
    end


    def not_found(conn, _params) do
        put_status(conn, 404)
        |> render(:error, layout: false)
    end

    def landing(conn, _params) do
        render(conn, :landing, layout: false, hide_header: true)
    end
end
