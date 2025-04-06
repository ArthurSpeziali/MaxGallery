defmodule MaxGalleryWeb.PageController do
    use MaxGalleryWeb, :controller


    def home(conn, _params) do
        # The home page is often custom made,
        # so skip the default app layout.
        render(conn, :home, layout: false)
    end

    def auth(conn, %{"auth" => key}) do
        put_session(conn, :auth?, true)
        |> put_session(:auth_params, key)
        |> redirect(to: "/data")
    end
    def auth(conn, _params) do
        redirect(conn, to: "/")
    end
end
