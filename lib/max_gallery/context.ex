defmodule MaxGallery.Context do
    alias MaxGallery.Core.Data.Api
    alias MaxGallery.Encrypter
    alias MaxGallery.Phantom


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


    def decrypt_all(key) do
        {:ok, datas} = Api.all()

        querry = Enum.map(datas, fn item -> 
            {:ok, name} = {item.name_iv, item.name} |> Encrypter.decrypt(key)
            {:ok, blob} = {item.blob_iv, item.blob} |> Encrypter.decrypt(key)

            %{name: name <> item.ext, blob: blob, id: item.id}
        end) |> Phantom.encode_bin()

        {:ok, querry}
    end


    def cypher_delete(id) do
        case Api.delete(id) do
            {:ok, querry} -> {:ok, querry}
            error -> error
        end
    end
end
