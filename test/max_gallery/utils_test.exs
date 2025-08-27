defmodule MaxGallery.UtilsTest do
  use MaxGallery.DataCase
  alias MaxGallery.Utils
  alias MaxGallery.Context
  alias MaxGallery.TestHelpers

  setup do
    {:ok,
     msg: "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
     tree: [
       %{
         data: %{
           id: 143,
           name: "File",
           group: 46,
           blob: "This is A Tree!\nDo you believe?\n",
           ext: ".txt"
         }
       }
     ]}
  end

  defp create_file(msg) do
    TestHelpers.create_temp_file(msg)
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

    # 56 bytes the Lorem Ipsulum fragment
    assert 56 = Utils.get_size(id)
    
    TestHelpers.cleanup_temp_files()
  end
end