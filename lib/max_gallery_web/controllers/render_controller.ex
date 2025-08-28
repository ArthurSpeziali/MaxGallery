defmodule MaxGalleryWeb.RenderController do
  use MaxGalleryWeb, :controller
  require Logger
  alias MaxGallery.Context
  alias MaxGallery.Cache
  alias MaxGallery.Extension
  alias MaxGallery.Variables

  ## Decrypt the file and shows instantly.
  defp content_render(conn, id) do
    key = get_session(conn, :auth_key)
    user = get_session(conn, "user_auth")
    {:ok, querry} = Context.decrypt_one(user, id, key)

    mime =
      Map.fetch!(querry, :ext)
      |> Extension.get_mime()

    # Use blob content directly from memory
    content = Map.get(querry, :blob)

    if content do
      put_resp_content_type(conn, mime)
      |> send_resp(200, content)
    else
      redirect(conn, to: "/user/data")
    end
  end

  def images(conn, %{"id" => id}) do
    content_render(conn, id)
  end

  ## Load the file, and chunk it. It ensures the videos load faster.
  def videos(conn, %{"id" => id}) do
    key = get_session(conn, :auth_key)
    user = get_session(conn, "user_auth")

    # Get cypher info first to get blob_iv
    {:ok, cypher} = Context.decrypt_one(user, id, key, lazy: true)
    {:ok, cypher_full} = MaxGallery.Core.Cypher.Api.get(id)

    # Use cache to get file path for streaming
    {file_path, _was_downloaded} = Cache.consume_cache(user, id, cypher_full.blob_iv, key)

    if File.exists?(file_path) do
      mime = Extension.get_mime(cypher.ext)

      conn =
        put_resp_content_type(conn, mime)
        |> put_resp_header("accept-ranges", "bytes")
        |> send_chunked(200)

      File.stream!(file_path, [], Variables.chunk_size())
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
    user = get_session(conn, "user_auth")

    if key do
      {:ok, file_path} = Context.zip_content(user, id, key, group: true)

      Logger.debug(
        "Sending dowload from #{user}\n Path: #{file_path}\n" <> String.duplicate("!-", 50)
      )

      send_download(conn, {:file, file_path})
    else
      redirect(conn, to: "/user")
    end
  end

  def download(conn, %{"id" => id, "type" => "data"}) do
    key = get_session(conn, :auth_key)
    user = get_session(conn, "user_auth")

    if key do
      {:ok, file_path} = Context.zip_content(user, id, key)

      send_download(conn, {:file, file_path})
    else
      redirect(conn, to: "/user")
    end
  end

  def download(conn, _params) do
    redirect(conn, to: "/user/data")
  end
end
