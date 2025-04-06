defmodule MaxGalleryWeb.DataLive do
    use MaxGalleryWeb, :live_view
    alias MaxGallery.Context


    def mount(_params, %{"auth?" => true, "auth_params" => key_map}, socket) do
        key = key_map["key"]
        {:ok, datas} = Context.decrypt_all(key)
        
        {:ok, assign(socket, datas: datas), layout: false}
    end
    def mount(_params, _session, socket) do
        {:ok, redirect(socket, to: "/")}
    end

end
