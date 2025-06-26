defmodule MaxGallery.Extension do
    @moduledoc """
    Handles file extensions, MIME types, and size formatting for MaxGallery.

    This module provides utilities for:

    ## File Type Management
    - Categorizes files into types (audio, text, image, video)
    - Maintains comprehensive lists of supported extensions
    - Provides MIME type detection
    - Fallback behavior for unknown types

    ## Core Functionality
    - `get_ext/1` - Determines file category from extension
    - `get_mime/1` - Maps extensions to proper MIME types  
    - `convert_size/1` - Formats byte sizes for human readability

    ## Supported Formats
    - Audio: MP3, WAV, OGG, FLAC, AAC and others
    - Text: TXT, CSV, JSON, HTML and many document formats
    - Image: JPG, PNG, GIF, SVG, WEBP and other image formats
    - Video: MP4, MKV, AVI, MOV, WEBM and other video formats

    ## Design Features
    - Internal extension lists are private but comprehensive
    - Smart fallbacks (unknown files treated as text)
    - HTML5-compatible MIME types
    - Human-friendly size formatting
    - Optimized for fast lookups
    """



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
        # Video
        mp4: "video/mp4",
        m4v: "video/x-m4v",
        webm: "video/webm",
        mpeg: "video/mpeg",
        mpg: "video/mpeg",
        avi: "video/x-msvideo",
          mkv: "video/x-matroska", # This MIME don't work in HTML5!
        wmv: "video/x-ms-wmv",
        mov: "video/quicktime",
        "3gp": "video/3gpp",
        "3g2": "video/3gpp2",
        ogv: "video/ogg",
        flv: "video/x-flv",
        ts: "video/mp2t",

        # Image
        jpg: "image/jpeg",
        jpeg: "image/jpeg",
        png: "image/png",
        gif: "image/gif",
        svg: "image/svg+xml",
        webp: "image/webp",
        bmp: "image/bmp",
        tiff: "image/tiff",
        tif: "image/tiff",
        ico: "image/x-icon",
        heic: "image/heic",
        heif: "image/heif",
        avif: "image/avif",

        # Audio
        mp3: "audio/mpeg",
        ogg: "audio/ogg",
        oga: "audio/ogg",
        wav: "audio/wav",
        aac: "audio/aac",
        flac: "audio/flac",
        midi: "audio/midi",
        mid: "audio/midi",
        m4a: "audio/mp4",
        opus: "audio/opus",
        amr: "audio/amr",

        # Documents
        pdf: "application/pdf",
        odp: "application/vnd.oasis.opendocument.presentation",
        ods: "application/vnd.oasis.opendocument.spreadsheet",
        odt: "application/vnd.oasis.opendocument.text",
        docx: "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
        xlsx: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        pptx: "application/vnd.openxmlformats-officedocument.presentationml.presentation",
        ppt: "application/vnd.ms-powerpoint",
        doc: "application/msword",
        xls: "application/vnd.ms-excel"
      }
    end


    @doc """
    Determines the file category based on its extension.

    ## Parameters
    - `ext`: String - The file extension including dot (e.g. ".mp3")

    ## Returns
    String - The file category ("audio", "text", "image", or "video").
             Returns "text" for unknown extensions.
    """
    @spec get_ext(ext :: String.t()) :: String.t()
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

    @doc """
    Maps a file extension to its corresponding MIME type.

    ## Parameters
    - `ext`: String - The file extension including the dot (e.g. ".jpg", ".mp4")

    ## Returns
    String - The corresponding MIME type string. Returns "image/png" as default for:
             - Unknown extensions
             - Invalid input formats
             - nil values

    ## Behavior
    1. Strips the leading dot from the extension
    2. Converts to atom for efficient Map lookup
    3. Performs case-sensitive match against known MIME types
    4. Falls back to "image/png" when no match found

    ## Performance
    - Uses atom conversion for fast Map lookup
    - Minimal string manipulation
    - Single Map traversal
    """
    @spec get_mime(ext :: String.t()) :: String.t()
    def get_mime(ext) do
        atom_ext = String.slice(ext, 1..-1//1)
                   |> String.to_atom()

        mime = mime_map()
               |> Map.get(atom_ext)
               |> IO.inspect #*@SJU@DNUI@HD

        case mime do
            nil -> "image/png"
            mime -> mime
        end
    end


    @doc """
    Converts byte size to human-readable format with appropriate unit.

    ## Parameters
    - `bytes`: Integer - File size in bytes

    ## Returns
    String - Formatted size with unit (e.g. "1.23 Mb")

    ## Conversion Rules
    - < 1 KB: displays in bytes (e.g. "512 B")
    - 1 KB to 1 MB: displays in kilobytes (e.g. "2.5 KB")
    - 1 MB to 1 GB: displays in megabytes (e.g. "150.75 MB")
    - > 1 GB: displays in gigabytes (e.g. "3.5 GB")
    """
    @spec convert_size(bytes :: non_neg_integer()) :: String.t()
    def convert_size(bytes) when is_integer(bytes) do
        case bytes do
            x when x > 1024 * 1024 * 1024 -> "#{x / 1024 ** 3 |> Float.round(2)} Gb"
            x when x > 1024 * 1024 -> "#{x / 1024 ** 2 |> Float.round(2)} Mb"
            x when x > 1024 -> "#{x / 1024 |> Float.round(2)} Kb"
            x -> "#{x} B"
        end
    end
end
