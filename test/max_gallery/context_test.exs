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
        path = "/tmp/max_gallery/test#{Enum.random(0..10_000//1)}"
        File.mkdir("/tmp/max_gallery")
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
            Context.cypher_insert(path, "key")
        end

        assert {:ok, querry} = Context.decrypt_all("key")
        assert %{name: name, blob: ^msg} = List.first(querry)
        assert ^name = Path.basename(path)
    end
end
