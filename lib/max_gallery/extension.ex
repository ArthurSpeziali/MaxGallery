defmodule MaxGallery.Extension do

    defp exts(:audio) do 
       [:mp3, :wav, :ogg, :flac, :aac, :m4a, :wma, :alac, :aiff, :amr, :opus, :mid, :midi, :pcm, :ra]
    end
    defp exts(:text) do
        [:txt, :csv, :tsv, :log, :md,:markdown, :rst, :adoc, :doc, :xml, :json, :yaml, :yml, :ini, :toml, :tex, :html, :htm, :env, :sh, :bat, :ps1, :conf, :cfg]
    end
    defp exts(:image) do
        [:jpg, :jpeg, :png, :gif, :bmp, :webp, :svg, :tiff, :tif, :ico, :heif, :heic, :avif, :raw, :psd, :eps, :ai, :pdf]
    end
    defp exts(:video) do
        [:mp4, :mkv, :avi, :mov, :wmv, :flv, :webm, :mpeg, :mpg, :"3gp", :m4v, :ts, :m2ts, :ogv, :vob]
    end

    defp mime_map() do
        %{
          mp4: "video/mp4",
          webm: "video/webm",
          mpeg: "video/mpeg",
          avi: "video/x-msvideo",
          mkv: "video/x-matroska", # This file type does not work in html 5!
          wmv: "video/x-ms-wmv",
          mov: "video/quicktime",
          "3gp": "video/3gpp",
          jpg: "image/jpeg",
          jpeg: "image/jpeg",
          png: "image/png",
          gif: "image/gif",
          svg: "image/svg+xml",
          webp: "image/webp",
          bmp: "image/bmp",
          tiff: "image/tiff",
          ico: "image/x-icon",
          mp3: "audio/mpeg",
          ogg: "audio/ogg",
          wav: "audio/wav",
          aac: "audio/aac",
          flac: "audio/flac",
          midi: "audio/midi",
          m4a: "audio/mp4",
        }
    end


    def get_ext(ext) do
        atom_ext = String.slice(ext, 1..-1//1)
                   |> String.to_atom()

        cond do
            atom_ext in exts(:audio) -> "audio"
            atom_ext in exts(:text) -> "text"
            atom_ext in exts(:image) -> "image"
            atom_ext in exts(:video) -> "video"
            true -> "text" # If none, compile as text binary
        end
    end

    def get_mime(ext) do
        atom_ext = String.slice(ext, 1..-1//1)
                   |> String.to_atom()

        mime = mime_map()
               |> Map.get(atom_ext)

        case mime do
            nil -> "image/png"
            mime -> mime
        end
    end
end
