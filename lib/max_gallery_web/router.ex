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

        get "/", PageController, :home
        post "/auth", PageController, :auth
        get "/logout", PageController, :logout
        get "/download", PageController, :download

        live "/data", DataLive
        live "/editor", EditorLive
        live "/show", ShowLive
        live "/import", ImportLive
        live "/move", MoveLive
        live "/config", ConfigLive

        live "/data/:id", DataLive
        live "/import/:id", ImportLive
        live "/move/:id", MoveLive
    end

    scope "/content", MaxGalleryWeb do
        pipe_through :browser

        get "/imgs/:id", PageController, :images
        get "/vids/:id", PageController, :videos
        get "/auds/:id", PageController, :audios
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
