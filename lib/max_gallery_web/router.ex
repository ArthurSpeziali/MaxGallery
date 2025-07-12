defmodule MaxGalleryWeb.Router do
  use MaxGalleryWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {MaxGalleryWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", MaxGalleryWeb do
    pipe_through :browser

    get "/", PageController, :landing
    get "/email-verify", PageController, :email_verify
    post "/email-verify", PageController, :email_verify_process
  end

  scope "/", MaxGalleryWeb.Live do
    pipe_through :browser

    live "/login", LoginLive
  end

  scope "/user", MaxGalleryWeb do
    pipe_through :browser

    get "/", PageController, :home
    get "/logout", PageController, :logout
    get "/download", RenderController, :download
  end

  scope "/user", MaxGalleryWeb.Live do
    pipe_through :browser

    live "/data", DataLive
    live "/editor", EditorLive
    live "/show", ShowLive
    live "/import", ImportLive
    live "/move", MoveLive
    live "/config", ConfigLive

    live "/editor/:page_id", EditorLive
    live "/data/:id", DataLive
    live "/import/:id", ImportLive
    live "/move/:id", MoveLive
  end

  scope "/content", MaxGalleryWeb do
    pipe_through :browser

    get "/imgs/:id", RenderController, :images
    get "/vids/:id", RenderController, :videos
    get "/auds/:id", RenderController, :audios
  end

  scope "/request", MaxGalleryWeb do
    pipe_through :browser

    post "/auth", RequestController, :auth
    get "/auth-user", RequestController, :auth_user
    get "/email-check", RequestController, :email_check
  end

  scope "/", MaxGalleryWeb do
    pipe_through :browser

    ## Catch all invalid URLs, from any VERB.
    match :*, "/*any", PageController, :not_found
  end

  # Other scopes may use custom stacks.
  # scope "/api", MaxGalleryWeb do
  #     pipe_through :api
  # end
end
