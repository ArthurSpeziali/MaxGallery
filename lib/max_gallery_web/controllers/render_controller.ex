defmodule MaxGalleryWeb.RenderController do
  use MaxGalleryWeb, :controller
  require Logger
  alias MaxGallery.Context
  alias MaxGallery.Phantom
  alias MaxGallery.Extension
  alias MaxGallery.Validate
  alias MaxGallery.Variables

  @type plug :: %Plug.Conn{}


  ## Decrypt the file and shows instantly.
  @spec content_render(conn :: plug(), id :: integer()) :: plug()
  def content_render(conn, id) do
    id = Validate.int!(id)
    key = get_session(conn, :auth_key)
    user = get_session(conn, "user_auth")
    {:ok, querry} = Context.decrypt_one(user, id, key)

    mime =
      Map.fetch!(querry, :ext)
      |> Extension.get_mime()

    # Use blob content directly from memory
    path = Map.get(querry, :path)

    if path && File.exists?(path) do
      content = File.read!(path)

      put_resp_content_type(conn, mime)
      |> send_resp(200, content)
    else
      redirect(conn, to: "/user/data")
    end
  end

  @spec images(conn :: plug(), map()) :: plug()
  def images(conn, %{"id" => id}) do
    id = Validate.int!(id)
    content_render(conn, id)
  end

  ## Load the file, and chunk it. It ensures the videos load faster.
  @spec videos(conn :: plug(), map()) :: plug()
  def videos(conn, %{"id" => id}) do
    id = Validate.int!(id)
    key = get_session(conn, :auth_key)
    user = get_session(conn, "user_auth")

    # Get cypher info first to get blob_iv
    {:ok, cypher} = Context.decrypt_one(user, id, key)

    mime = Extension.get_mime(cypher.ext)

    conn =
      put_resp_content_type(conn, mime)
      |> send_chunked(200)

    File.stream!(cypher.path, Variables.chunk_size())
    |> Enum.reduce_while(conn, fn chunk, conn ->
      case chunk(conn, chunk) do
        {:ok, conn} ->
          {:cont, conn}

        {:error, :closed} ->
          {:halt, conn}
      end
    end)
  end

  @spec audios(conn :: plug(), map()) :: plug()
  def audios(conn, %{"id" => id}) do
    id = Validate.int!(id)
    content_render(conn, id)
  end

  def download(conn, %{"id" => id, "type" => "group"}) do
    id = Validate.int!(id)
    key = get_session(conn, :auth_key)
    user = get_session(conn, "user_auth")


    if key && Phantom.insert_line?(user, key) do
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
    id = Validate.int!(id)
    key = get_session(conn, :auth_key)
    user = get_session(conn, "user_auth")

    if key && Phantom.insert_line?(user, key) do
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
