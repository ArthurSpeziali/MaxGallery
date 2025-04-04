defmodule MaxGallery.Core.Data.Context do
    alias MaxGallery.Core.Data.Api
    alias MaxGallery.Encrypter


    def cypher_insert(path, key) do
        with ext <- Path.extname(path),
             {:ok, {name_iv, name}} <- Path.basename(path, ext) |> Encrypter.encrypt(key),
             {:ok, {blob_iv, blob}} <- Encrypter.file(:encrypt, path, key),
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


    def show_all() do
        {:ok, datas} = Api.all()

        querry = Enum.map(datas, fn item -> 
            {item.name, item.blob}
        end)

        {:ok, querry}
    end

    def decrypt_all(key) do
        {:ok, datas} = Api.all()

        querry = Enum.map(datas, fn item -> 
            {:ok, name} = {item.name_iv, item.name} |> Encrypter.decrypt(key)
            {:ok, blob} = {item.blob_iv, item.blob} |> Encrypter.decrypt(key)
            {name <> item.ext, blob}
        end)

        {:ok, querry}
    end
end
