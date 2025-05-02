defmodule MaxGallery.Data.ContextTest do
    use MaxGallery.DataCase
    alias MaxGallery.Context
    alias MaxGallery.Core.Data.Api

    
    setup do
        {:ok,
            msg: "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
            data: %{name: <<0>>, blob: <<0>>, ext: ""}
        }
    end

    defp create_file(msg) do
        path = "/tmp/max_gallery/tests/test#{Enum.random(0..10_000//1)}"
        File.mkdir("/tmp/max_gallery/tests")
        File.write(path, msg, [:write])
        path
    end


    test "Create a file, put it encrypted in the database, then get it", %{msg: msg} do
        path = create_file(msg)
        assert {:ok, id} = Context.cypher_insert(path, "key")
        assert {:ok, _querry} = Api.get(id)
    end

    test "Insert 10 cyphers and decrypt them", %{msg: msg} do
        path = create_file(msg)
        
        for _item <- 1..10//1 do 
            assert {:ok, _querry} = Context.cypher_insert(path, "key")
        end

        assert {:ok, querry} = Context.decrypt_all("key")
        assert %{name: name, blob: ^msg} = List.first(querry)
        assert ^name = Path.basename(path)
    end

    test "Insert an data, then update its content.", %{msg: msg} do
        path = create_file(msg)
        
        assert {:ok, id} = Context.cypher_insert(path, "key")
        assert {:ok, data} = Context.decrypt_one(id, "key")
        assert {:ok, _querry} = Context.cypher_update(id, %{name: data.name <> data.ext, blob: data.blob}, "key")
    end

    test "Insert 10 groups, then remove them." do
        id_list = 
            for item <- 1..10//1 do
                assert {:ok, _id} = Context.group_insert("Group#{item}", "key")
            end


        for {:ok, id} <- id_list do
            assert {:ok, _querry} = Context.group_delete(id, "key")
        end
    end

    test "2 forms to update a group." do
        assert {:ok, group_id} = Context.group_insert("Group0", "key")
        assert {:ok, id} = Context.group_insert("Group1", "key")

        assert {:ok, _querry} = Context.group_update(id, %{name: "Group2"}, "key")
        assert {:ok, _querry} = Context.group_update(id, %{group_id: group_id}, "key")
    end

    test "Duplicate a cypher, and a group", %{msg: msg} do
        path = create_file(msg)

        assert {:ok, data_id} = Context.cypher_insert(path, "key")
        assert {:ok, main_id} = Context.group_insert("Main", "key")
        assert {:ok, group_id} = Context.group_insert("Group1", "key")

        assert {:ok, _querry} = Context.cypher_duplicate(data_id, %{group_id: main_id}, "key")
        assert {:ok, _querry} = Context.group_duplicate(data_id, %{group_id: group_id}, "key")
    end

    test "Insert 5 cyphers and 5 groups, then check your size", %{msg: msg} do
        path = create_file(msg)

        for item <- 1..5//1 do
            assert {:ok, _querry} = Context.cypher_insert(path, "key")
            assert {:ok, _querry} = Context.group_insert("Group#{item}", "key")
        end

        assert {:ok, querry} = Context.decrypt_all("key")
        assert 10 = length(querry)
    end
end
