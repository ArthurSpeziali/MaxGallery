defmodule MaxGallery.Utils do
    alias MaxGallery.Core.Data.Api, as: DataApi
    alias MaxGallery.Core.Group.Api, as: GroupApi
    alias MaxGallery.Core.Bucket
    alias MaxGallery.Encrypter
    alias MaxGallery.Phantom


    def get_back(id) do
        case id do
            nil -> nil
            _id ->
                {:ok, querry} = GroupApi.get(id)
                Map.fetch!(querry, :group_id)
        end
    end

    def get_group(id, opts \\ []) do
        only = Keyword.get(opts, :only)

        case only do
            nil ->
                {:ok, datas} = DataApi.all_group(id)
                {:ok, groups} = GroupApi.all_group(id)

                {:ok, groups ++ datas}


            :datas ->
                DataApi.all_group(id)


            :groups ->
                GroupApi.all_group(id)
        end
    end

    def get_size(id, opts \\ []) do
        group? = Keyword.get(opts, :group)

        if group? do
            {:ok, contents} = get_group(id)

            if contents == [] do
                0
            else
                Enum.map(contents, fn item ->
                    subgroup? = 
                        if Map.get(item, :ext) do
                            nil
                        else
                            true
                        end

                    get_size(item.id, group: subgroup?)
                end) |> Enum.sum()
            end
        else
            {:ok, querry} = DataApi.get(id)
            
            {:ok, file} = Bucket.get(querry.file_id)
            file["length"]
        end
    end

    def get_timestamps(id, opts \\ []) do
        group? = Keyword.get(opts, :group)

        {:ok, timestamps} = 
            if group? do
                GroupApi.get_timestamps(id)
            else
                DataApi.get_timestamps(id)
            end

        local = NaiveDateTime.local_now()
        utc = NaiveDateTime.utc_now()
        diff = NaiveDateTime.diff(local, utc, :hour)

        Map.update!(timestamps, :inserted_at, fn item -> 
            NaiveDateTime.add(item, diff, :hour)
        end) |> Map.update!(:updated_at, fn item -> 
            NaiveDateTime.add(item, diff, :hour)
        end)
    end

    def get_tree(id, key) do
        {:ok, contents} = get_group(id)

        if contents == [] do
            []
        else
            Enum.map(contents, fn item -> 
                if Map.get(item, :ext) do
                    {:ok, name} = Encrypter.decrypt(
                        {item.name_iv, item.name}, 
                        key
                    ) 

                    {:ok, blob} = Encrypter.decrypt(
                        {item.blob_iv, item.blob},
                        key
                    )

                    %{data: %{
                        id: item.id,
                        name: name,
                        blob: blob,
                        ext: item.ext,
                        group: item.group_id
                    }}
                else
                    {:ok, name} = Encrypter.decrypt(
                            {item.name_iv, item.name}, 
                            key
                    )

                    %{group: {
                        %{
                            id: item.id,
                            name: name,
                            group: item.group_id
                        },
                        get_tree(item.id, key)
                    }}
                end
            end)
        end
    end


    def mount_tree(tree, params, fun, key) when is_function(fun, 2) do
        Enum.each(tree, fn item -> 

            case item do
                %{data: data} -> 
                    {:ok, {name_iv, name}} = Encrypter.encrypt(data.name, key)
                    {:ok, {blob_iv, blob}} = Encrypter.encrypt(data.blob, key)
                    {:ok, {msg_iv, msg}} = Phantom.get_text() 
                                    |> Encrypter.encrypt(key)

                    %{id: data.id, name: name, name_iv: name_iv, blob: blob, blob_iv: blob_iv, msg: msg, msg_iv: msg_iv, ext: data.ext, group_id: data.group}
                    |> Map.merge(params)
                    |> fun.(:data)


                %{group: {group, subitems}} -> 
                    {:ok, {name_iv, name}} = Encrypter.encrypt(group.name, key)
                    {:ok, {msg_iv, msg}} = Phantom.get_text()
                                           |> Encrypter.encrypt(key)

                    sub_params = 
                        %{id: group.id, name: name, name_iv: name_iv, msg: msg, msg_iv: msg_iv, group_id: group.group}
                        |> Map.merge(params)
                        |> fun.(:group)

                    mount_tree(subitems, sub_params, fun, key)
            end

        end)
    end

    defp extract_tree(tree) do
        Enum.map(tree, fn item -> 

            case item do
                %{data: data} ->
                    {data.name <> data.ext, data.blob}


                %{group: {group, subitems}} ->
                    {group.name, extract_tree(subitems)}
            end

        end)
    end


    def zip_file(name, blob) do
        File.mkdir_p("/tmp/max_gallery/zips")

        {:ok, final_path} = 
            :zip.create("/tmp/max_gallery/zips/#{name}_#{Enum.random(1..999//1)}.zip" |> String.to_charlist(), [
                {
                    name |> String.to_charlist(), 
                    blob
                }
            ])

        {:ok, final_path |> List.to_string()}
    end

    def zip_folder(tree, group_name) do 
        File.mkdir_p("/tmp/max_gallery/zips")
        folder = group_name <> "_#{Enum.random(1..1_000)}"
                 |> String.replace(" ", "_")
                 |> String.replace("/", "//")

        files = extract_tree(tree) 
               |> parse_path(group_name)

        {:ok, final_path} = 
            :zip.create(
                "/tmp/max_gallery/zips/#{folder}.zip" |> String.to_charlist(), 
                files
            )

        {:ok, final_path |> List.to_string()}
    end


    defp parse_path(tree, folder, back_folder \\ nil)
    defp parse_path([], _folder, _back_folder), do: []
    defp parse_path([head | tail], folder, back_folder) do
        {name, content} = head

        back_folder = 
            if back_folder do
                back_folder
            else
                folder
            end

        if is_list(content) do
            parse_path(
                content, 
                folder <> "/" <> name,
                back_folder
            )
        else
            [{
                folder <> "/" <> name |> String.to_charlist(), 
                content
            }] 
        end ++ parse_path(tail, folder, back_folder) 
    end


    # "=~" == Regex
    def get_like(querry, like) do
        Enum.filter(querry, fn item -> 
            String.downcase(
                item.name
            ) =~ String.downcase(
                like
            )
        end)
    end

end
