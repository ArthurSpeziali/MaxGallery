defmodule MaxGallery.UtilsTest do
    use ExUnit.Case
    alias MaxGallery.Utils
    alias MaxGallery.Context
    alias MaxGallery.Core.Bucket


    setup do
        Bucket.drop()
        Context.delete_all("key")

        {:ok,
            msg: "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
            tree: [
                %{data: %{
                    id: 143,
                    name: "File",
                    group: 46,
                    blob: "This is A Tree!\nDo you believe?\n",
                    ext: ".txt"}
                }]

        }
    end

    defp create_file(msg) do
        path = "/tmp/max_gallery/tests/test#{Enum.random(0..10_000//1)}"
        File.mkdir_p("/tmp/max_gallery/tests")
        File.write(path, msg, [:write])
        path
    end


    test "Zip a file", %{msg: msg} do
        assert {:ok, path} = Utils.zip_file("ZipFile", msg) 
        assert :ok = File.rm(path)
    end

    test "Zip a folder", %{tree: tree} do
        assert {:ok, path} = Utils.zip_folder(tree, "ZipFolder")
        assert :ok = File.rm(path)
    end

    test "Check the size", %{msg: msg} do
        path = create_file(msg)
        {:ok, id} = Context.cypher_insert(path, "key")

        assert 56 = Utils.get_size(id) # 56 bytes the Lorem Ipsulum fragment
    end
end
