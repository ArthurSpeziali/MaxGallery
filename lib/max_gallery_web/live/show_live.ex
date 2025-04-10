defmodule MaxGalleryWeb.ShowLive do
    use MaxGalleryWeb, :live_view
    alias MaxGallery.Server.LiveServer
    alias MaxGallery.Phantom


    def mount(%{"id" => id}, _session, socket) do
        data = LiveServer.get(:datas)
              |> Enum.find(fn item -> 
                  to_string(item.id) == id
              end) |> Phantom.encode_bin()
              |> List.first()

        key = LiveServer.get(:auth_key)

        socket = assign(socket, [
            data: data,
            auth_key: key
        ])

        {:ok, socket, layout: false}
    end
    def mount(_params, _session, socket) do
        {:ok, push_navigate(socket, to: "/data")}
    end
end
