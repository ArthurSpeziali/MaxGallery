defmodule MaxGallery.Context do
    alias MaxGallery.Core.Data.Api, as: DataApi
    alias MaxGallery.Core.Group.Api, as: GroupApi
    alias MaxGallery.Encrypter
    alias MaxGallery.Phantom


    def cypher_insert(path, key, opts \\ []) do
        key_name = Keyword.get(opts, :name) 

        ext = 
            if key_name do
                Path.extname(key_name)
            else
                Path.extname(path)
            end 

        {:ok, {name_iv, name}} = 
            if key_name do
                Path.basename(key_name, ext)
                |> Encrypter.encrypt(key)
            else
                Path.basename(path, ext)
                |> Encrypter.encrypt(key)
            end 


        with true <- Phantom.insert_line?(key),
             {:ok, {blob_iv, blob}} <- Encrypter.file(:encrypt, path, key),
             {:ok, {msg_iv, msg}} <- Encrypter.encrypt(Phantom.get_text(), key),
             {:ok, querry} <- DataApi.insert(%{
                 name: name,
                 name_iv: name_iv,
                 blob: blob,
                 blob_iv: blob_iv,
                 ext: ext,
                 msg: msg,
                 msg_iv: msg_iv}) do

            {:ok, querry.id}
        else
            error -> error
        end
    end


    defp send_package(%{ext: _ext} = item, lazy?, key) do
        {:ok, name} = {item.name_iv, item.name} |> Encrypter.decrypt(key)

        if lazy? do
            %{name: name, ext: item.ext, id: item.id}
        else
            {:ok, blob} = {item.blob_iv, item.blob} |> Encrypter.decrypt(key)
            %{name: name, blob: blob, ext: item.ext, id: item.id}
        end
    end
    defp send_package(item, _lazy, key) do
        {:ok, name} = {item.name_iv, item.name} |> Encrypter.decrypt(key)
        %{name: name, id: item.id} 
    end

    def decrypt_all(key, opts \\ []) do
        lazy? = Keyword.get(opts, :lazy)
        only = Keyword.get(opts, :only)

        {:ok, datas} = 
            case {lazy?, only} do
                {nil, nil} ->
                    {:ok, groups} = GroupApi.all() 
                    {:ok, datas} = DataApi.all()

                    {:ok, groups ++ datas}

                {true, nil} ->
                    {:ok, groups} = GroupApi.all() 
                    {:ok, datas} = DataApi.all_lazy()

                    {:ok, groups ++ datas}

                {nil, :datas} ->
                    DataApi.all()

                {true, :datas} ->
                    DataApi.all_lazy()

                {_boolean, :groups} ->
                    GroupApi.all()
            end


        querry = for item <- datas do
            send_package(item, lazy?, key)
        end |> Phantom.encode_bin()

        {:ok, querry}
    end


    def cypher_delete(id, key) do
        with {:ok, querry} <- DataApi.get(id),
             true <- Phantom.valid?(querry, key),
             {:ok, _querry} <- DataApi.delete(id) do
            
            {:ok, querry}
        else
            error -> error
        end
    end

    
    def decrypt_one(id, key, opts \\ []) do
        lazy? = Keyword.get(opts, :lazy)
        {:ok, querry} = 
            if lazy? do
                DataApi.get_lazy(id)
            else
                DataApi.get(id)
            end

        with {:ok, name} <- Encrypter.decrypt({querry.name_iv, querry.name}, key) do

            if lazy? do
                {:ok, %{
                    id: id,
                    name: name,
                    ext: querry.ext
                }}
            else
                {:ok, blob} = Encrypter.decrypt({querry.blob_iv, querry.blob}, key)

                {:ok, %{
                    id: id,
                    name: name,
                    blob: blob,
                    ext: querry.ext
                }}
            end
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
        {:ok, querry} = DataApi.get(id)

        if Phantom.valid?(querry, key) do
            DataApi.update(id, params)
        end
    end
    def cypher_update(id, %{name: new_name}, key) do
        ext = Path.extname(new_name)
        new_name = Path.basename(new_name, ext)

        {:ok, {name_iv, name}} = Encrypter.encrypt(new_name, key)

        params = %{name_iv: name_iv, name: name, ext: ext}
        {:ok, querry} = DataApi.get(id)

        if Phantom.valid?(querry, key) do
            DataApi.update(id, params)
        end
    end


    def group_insert(group_name \\ "New Group", key) do
        if Phantom.insert_line?(key) do
            {:ok, {name_iv, name}} = Encrypter.encrypt(group_name, key)
            {:ok, {msg_iv, msg}} = Phantom.get_text() |> Encrypter.encrypt(key)

            GroupApi.insert(%{name_iv: name_iv, name: name, msg_iv: msg_iv, msg: msg})
        end
    end

    def group_update(id, new_name, key) do 
        {:ok, querry} = GroupApi.get(id)
        {:ok, {name_iv, name}} = Encrypter.encrypt(new_name, key)

        if Phantom.valid?(querry, key) do
            GroupApi.update(id, %{name: name, name_iv: name_iv})
        end
    end
end
