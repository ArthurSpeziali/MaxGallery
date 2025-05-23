defmodule MaxGallery.UtilsTest do
    use MaxGallery.DataCase
    alias MaxGallery.Utils


    setup do
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


    test "Zip a file", %{msg: msg} do
        assert {:ok, path} = Utils.zip_file("ZipFile", msg) 
        assert :ok = File.rm(path)
    end

    test "Zip a folder", %{tree: tree} do
        assert {:ok, path} = Utils.zip_folder(tree, "ZipFolder")
        assert :ok = File.rm(path)
    end
end
