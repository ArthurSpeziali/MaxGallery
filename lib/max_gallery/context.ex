defmodule MaxGallery.Context do
    alias MaxGallery.Core.Data.Api, as: DataApi
    alias MaxGallery.Core.Group.Api, as: GroupApi
    alias MaxGallery.Encrypter
    alias MaxGallery.Phantom
    alias MaxGallery.Utils


    def cypher_insert(path, key, opts \\ []) do
        name = Keyword.get(opts, :name) 
        group = Keyword.get(opts, :group)

        ext = 
            if name do
                Path.extname(name)
            else
                Path.extname(path)
            end 

        {:ok, {name_iv, name}} = 
            if name do
                Path.basename(name, ext)
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
                 msg_iv: msg_iv,
                 group_id: group}) do

            {:ok, querry.id}
        else
            error -> error
        end
    end


    defp send_package(%{ext: _ext} = item, lazy?, key) do
        {:ok, name} = {item.name_iv, item.name} |> Encrypter.decrypt(key)

        if lazy? do
            %{name: name, ext: item.ext, id: item.id, group: item.group_id}
        else
            {:ok, blob} = {item.blob_iv, item.blob} |> Encrypter.decrypt(key)
            %{name: name, blob: blob, ext: item.ext, id: item.id, group: item.group_id}
        end
    end
    defp send_package(item, _lazy, key) do
        {:ok, name} = {item.name_iv, item.name} |> Encrypter.decrypt(key)
        %{name: name, id: item.id, group: item.group_id} 
    end

    def decrypt_all(key, opts \\ []) do
        lazy? = Keyword.get(opts, :lazy)
        only = Keyword.get(opts, :only)
        group_id = Keyword.get(opts, :group)

        {:ok, contents} = Utils.get_group(group_id, lazy: lazy?, only: only)

        querry = for item <- contents do
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
            false -> {:error, "invalid key"}
            error -> error
        end
    end

    
    def decrypt_one(id, key, opts \\ []) do
        lazy? = Keyword.get(opts, :lazy)
        group? = Keyword.get(opts, :group)

        {:ok, querry} = 
            case {lazy?, group?} do
                {true, nil} ->
                    DataApi.get_lazy(id)

                {nil, nil} ->
                    DataApi.get(id)

                {_boolean, true} ->
                    GroupApi.get(id)
            end

        with {:ok, name} <- Encrypter.decrypt({querry.name_iv, querry.name}, key) do

            case {lazy?, group?} do
                {true, nil} ->
                    {:ok, %{
                        id: id,
                        name: name,
                        ext: querry.ext,
                        group: querry.group_id
                    }}
                
                {nil, nil} ->
                    {:ok, blob} = Encrypter.decrypt({querry.blob_iv, querry.blob}, key)

                    {:ok, %{
                        id: id,
                        name: name,
                        blob: blob,
                        ext: querry.ext,
                        group: querry.group_id
                    }}

                {_boolean, true} ->
                    {:ok, %{
                        id: id,
                        name: name,
                        group: querry.group_id
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
        else
            {:error, "invalid key"}
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
        else
            {:error, "invalid key"}
        end
    end
    def cypher_update(id, %{group_id: new_group}, key) do
        {:ok, querry} = DataApi.get(id)

        if Phantom.valid?(querry, key) do
            DataApi.update(id, %{group_id: new_group})
        end
    end


    def group_insert(group_name, key, opts \\ []) do
        group = Keyword.get(opts, :group)

        if Phantom.insert_line?(key) do
            {:ok, {name_iv, name}} = Encrypter.encrypt(group_name, key)
            {:ok, {msg_iv, msg}} = Phantom.get_text() |> Encrypter.encrypt(key)

            {:ok, querry} = GroupApi.insert(%{name_iv: name_iv, name: name, msg_iv: msg_iv, msg: msg, group_id: group})
            {:ok, querry.id}
        end
    end

    def group_update(id, %{name: new_name}, key) do 
        {:ok, querry} = GroupApi.get(id)
        {:ok, {name_iv, name}} = Encrypter.encrypt(new_name, key)

        if Phantom.valid?(querry, key) do
            GroupApi.update(id, %{name: name, name_iv: name_iv})
        else
            {:error, "invalid key"}
        end
    end
    def group_update(id, %{group_id: group_id}, key) do
        {:ok, querry} = GroupApi.get(id)

        if Phantom.valid?(querry, key) do
            GroupApi.update(id, %{group_id: group_id})
        else
            {:error, "invalid key"}
        end
    end

    def group_delete(id, key) do
        with {:ok, querry} <- GroupApi.get(id),
             true <- Phantom.valid?(querry, key),
             {:ok, _querry} <- GroupApi.delete(id) do

            {:ok, querry}
        else
            false -> {:error, "invalid key"}
            error -> error
        end
    end

    def cypher_duplicate(id, params, key) do
        {:ok, querry} = DataApi.get(id)

        original = Map.drop(querry, [
            :__struct__,
            :__meta__,
            :id,
            :group,
            :inserted_at,
            :updated_at
        ])
        duplicate = Map.merge(original, params)
        
        {:ok, dec_name} = Encrypter.decrypt(
            {duplicate.name_iv, duplicate.name},
            key
        ) 

        {:ok, {name_iv, name}} = Encrypter.encrypt(
            dec_name,
            key
        )

        {:ok, {msg_iv, msg}} = Phantom.get_text()
                        |> Encrypter.encrypt(key)

        duplicate = Map.merge(duplicate,
            %{name_iv: name_iv, name: name, msg_iv: msg_iv, msg: msg}
        )

        with true <- Phantom.insert_line?(key),
             {:ok, querry} <- DataApi.insert(duplicate) do

            {:ok, querry.id}
        else
            error -> error
        end
    end


    def group_duplicate(id, params, key) do
        {:ok, querry} = GroupApi.get(id)

        original = Map.drop(querry, [
            :__struct__,
            :__meta,
            :id,
            :group,
            :cypher,
            :subgroup,
            :inserted_at,
            :updated_at
        ])

        duplicate = Map.merge(original, params)
        
        {:ok, dec_name} = Encrypter.decrypt(
            {duplicate.name_iv, duplicate.name},
            key
        ) 

        {:ok, {name_iv, name}} = Encrypter.encrypt(
            dec_name,
            key
        )

        {:ok, {msg_iv, msg}} = Phantom.get_text()
                        |> Encrypter.encrypt(key)

        duplicate = Map.merge(duplicate,
            %{name_iv: name_iv, name: name, msg_iv: msg_iv, msg: msg}
        )

        with true <- Phantom.insert_line?(key), 
             {:ok, querry} <- GroupApi.insert(duplicate) do
    
            {:ok, querry.id}
        else
            error -> error
        end         
    end


    def zip_content(id, key, opts \\ []) do
        group? = Keyword.get(opts, :group)

        if group? do

            case GroupApi.get(id) do
                {:ok, querry} ->
                    {:ok, name} = Encrypter.decrypt(
                        {querry.name_iv, querry.name},
                        key
                    )

                    tree = Utils.get_tree(id, key)
                    Utils.zip_folder(tree, name)


                error -> error
            end
        else

            case DataApi.get(id) do
                {:ok, querry} ->
                    {:ok, name} = Encrypter.decrypt(
                        {querry.name_iv, querry.name},
                        key
                    )
                    {:ok, blob} = Encrypter.decrypt(
                        {querry.blob_iv, querry.blob},
                        key
                    )

                    Utils.zip_file(
                        name <> querry.ext,
                        blob
                    )


                error -> error
            end
        end

    end


    def delete_all() do
        with {count_group, nil} <- GroupApi.delete_all(),
             {count_data, nil} <- DataApi.delete_all() do

            {:ok, count_group + count_data}
        else
            error -> error
        end
    end

    def update_all(key, new_key) do
        {:ok, group_list} = GroupApi.all()
        Enum.each(group_list, fn group ->
            {:ok, old_name} = Encrypter.decrypt(
                {group.name_iv, group.name},
                key
            )
            {:ok, {name_iv, name}} = Encrypter.encrypt(
                old_name,
                new_key
            )

            {:ok, {msg_iv, msg}} = Encrypter.encrypt(
                Phantom.get_text(),
                new_key
            )

            GroupApi.update(
                group.id, 
                %{name_iv: name_iv, name: name, msg_iv: msg_iv, msg: msg}
            )
        end)

        
        {:ok, data_list} = DataApi.all()
        Enum.each(data_list, fn data ->
            {:ok, old_name} = Encrypter.decrypt(
                {data.name_iv, data.name},
                key
            )
            {:ok, {name_iv, name}} = Encrypter.encrypt(
                old_name,
                new_key
            )

            {:ok, old_blob} = Encrypter.decrypt(
                {data.blob_iv, data.blob},
                key
            )
            {:ok, {blob_iv, blob}} = Encrypter.encrypt(
                old_blob,
                new_key
            )

            {:ok, {msg_iv, msg}} = Encrypter.encrypt(
                Phantom.get_text(),
                new_key
            )

            DataApi.update(
                data.id, 
                %{name_iv: name_iv, name: name, blob_iv: blob_iv, blob: blob, msg_iv: msg_iv, msg: msg}
            )
        end)

        count = Enum.count(group_list) + Enum.count(data_list) 
        {:ok, count}
    end

end
