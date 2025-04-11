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


    def get_ext(ext) do
        atom_ext = String.to_atom(ext)

        cond do
            atom_ext in exts(:audio) -> :audio
            atom_ext in exts(:text) -> :text
            atom_ext in exts(:image) -> :image
            atom_ext in exts(:video) -> :video
            true -> nil
        end
    end


end
