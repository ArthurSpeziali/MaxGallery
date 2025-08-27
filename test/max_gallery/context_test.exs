defmodule MaxGallery.ContextTest do
  use MaxGallery.DataCase
  alias MaxGallery.Context
  alias MaxGallery.Core.Cypher.Api
  alias MaxGallery.TestHelpers

  setup do
    {:ok,
     msg: "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
     data: %{name: <<0>>, blob: <<0>>, ext: ""}}
  end

  defp create_file(msg) do
    TestHelpers.create_temp_file(msg)
  end

  test "Create a file, put it encrypted in the database, then get it", %{msg: msg} do
    path = create_file(msg)
    assert {:ok, id} = Context.cypher_insert(path, "key")
    assert {:ok, _querry} = Api.get(id)
    TestHelpers.cleanup_temp_files()
  end

  test "Insert 10 cyphers and decrypt them", %{msg: msg} do
    path = create_file(msg)

    for _item <- 1..10//1 do
      assert {:ok, _querry} = Context.cypher_insert(path, "key")
    end

    assert {:ok, querry} = Context.decrypt_all("key")
    
    # The new system returns blob directly, not path
    assert %{name: name, blob: blob} = List.first(querry)
    assert ^msg = blob
    assert ^name = Path.basename(path, Path.extname(path))
    
    TestHelpers.cleanup_temp_files()
  end

  test "Insert an data, then update its content.", %{msg: msg} do
    path = create_file(msg)

    assert {:ok, id} = Context.cypher_insert(path, "key")
    assert {:ok, data} = Context.decrypt_one(id, "key")
    assert blob = data.blob

    assert {:ok, _querry} =
             Context.cypher_update(id, %{name: data.name <> data.ext, blob: blob}, "key")
             
    TestHelpers.cleanup_temp_files()
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

    assert {:ok, _id} = Context.cypher_duplicate(data_id, %{group_id: main_id}, "key")
    assert {:ok, _id} = Context.group_duplicate(group_id, %{group_id: group_id}, "key")
    
    TestHelpers.cleanup_temp_files()
  end

  test "Insert 5 cyphers and 5 groups, then check your size", %{msg: msg} do
    path = create_file(msg)

    for item <- 1..5//1 do
      assert {:ok, _querry} = Context.cypher_insert(path, "key")
      assert {:ok, _querry} = Context.group_insert("Group#{item}", "key")
    end

    assert {:ok, querry} = Context.decrypt_all("key")
    assert 10 = length(querry)
    
    TestHelpers.cleanup_temp_files()
  end

  test "Delete all cyphers", %{msg: msg} do
    path = create_file(msg)

    for item <- 1..5//1 do
      Context.cypher_insert(path, "key")
      Context.group_insert("Group#{item}", "key")
    end

    assert {:ok, 10} = Context.delete_all("key")
    
    TestHelpers.cleanup_temp_files()
  end

  test "Update all cyphers", %{msg: msg} do
    path = create_file(msg)

    for item <- 1..5//1 do
      Context.cypher_insert(path, "key")
      Context.group_insert("Group#{item}", "key")
    end

    assert {:ok, 10} = Context.update_all("key", "lock")
    assert {:error, "invalid key"} = Context.update_all("other_key", "key")
    assert {:ok, 10} = Context.update_all("lock", "key")
    
    TestHelpers.cleanup_temp_files()
  end
end