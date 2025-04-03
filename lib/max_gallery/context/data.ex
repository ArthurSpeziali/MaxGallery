defmodule MaxGallery.Data.Context do
    alias MaxGallery.Core.Data.Api
    alias MaxGallery.Encrypter


    def file_put(path, key) do
        with {:ok, content} <- File.read(path),
             ext <- Path.extname(path),
             {:ok, {name_iv, name}} <- Path.basename(path, ext) |> Encrypter.encrypt(key),
             {:ok, {blob_iv, blob}} <- Encrypter.encrypt(content, key),
             {:ok, querry} <- Api.insert(%{
                 name: name,
                 name_iv: name_iv,
                 blob: blob,
                 blob_iv: blob_iv,
                 ext: ext}) do

            {:ok, querry.id}
        else
            error -> error
        end
    end
end
