defmodule MaxGallery.Data.ContextTest do
    use MaxGallery.DataCase
    alias MaxGallery.Core.Data.Context
    alias MaxGallery.Core.Data.Api

    
    setup do
        {:ok,
            msg: "Lorem ipsum dolor sit amet, consectetur adipiscing elit."
        }
    end


    test "Create a file, put it encrypted in the database, then get it", %{msg: msg} do
        path = "/tmp/max_gallery/test#{Enum.random(0..10_000//1)}"
        File.mkdir("/tmp/max_gallery")
        File.write(path, msg, [:write])

        assert {:ok, id} = Context.file_put(path, "key")
        assert {:ok, _querry} = Api.get(id)
    end
end
