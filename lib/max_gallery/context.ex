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

            %{name: name, ext: item.ext, blob: blob, id: item.id}
        end) |> Phantom.encode_bin()

        {:ok, querry}
    end


    def cypher_delete(id, key) do
        with {:ok, querry} <- Api.get(id),
             true <- Phantom.valid?(querry, key),
             {:ok, _querry} <- Api.delete(id) do
            
            {:ok, querry}
        else
            error -> error
        end
    end

    
    def decrypt_one(id, key) do
        with {:ok, querry} <- Api.get(id),
             {:ok, name} <- Encrypter.decrypt({querry.name_iv, querry.name}, key),
             {:ok, blob} <- Encrypter.decrypt({querry.blob_iv, querry.blob}, key),
             ext <- querry.ext do

            {:ok, %{
                name: name,
                blob: blob,
                ext: ext
            }}
        else
            error -> error
        end
    end


    def cypher_update(id, %{name: new_name, blob: new_blob}, key) do
        ext = Path.extname(new_name)
        new_name = Path.basename(new_name, ext)

        {:ok, {name_iv, name}} = Encrypter.encrypt(new_name, key)
        {:ok, {blob_iv, blob}} = Encrypter.encrypt(new_blob, key)

        params = %{name_iv: name_iv, name: name, blob_iv: blob_iv, blob: blob, ext: ext}
        {:ok, querry} = Api.get(id)

        if Phantom.valid?(querry, key) do
            Api.update(id, params)
        end
    end

end
