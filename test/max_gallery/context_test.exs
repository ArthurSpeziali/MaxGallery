defmodule MaxGallery.ContextTest do
  use MaxGallery.DataCase
  alias MaxGallery.Context
  alias MaxGallery.Core.Cypher.Api
  alias MaxGallery.TestHelpers

  setup %{test_user: test_user} do
    # Ensure storage mock is started
    MaxGallery.Storage.Mock.start_link()

    {:ok,
     test_user: test_user,
     msg: "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
     data: %{name: <<0>>, blob: <<0>>, ext: ""}}
  end

  defp create_file(msg) do
    TestHelpers.create_temp_file(msg)
  end

  test "Create a file, put it encrypted in the database, then get it", %{
    msg: msg,
    test_user: test_user
  } do
    path = create_file(msg)
    assert {:ok, id} = Context.cypher_insert(path, test_user, "key")
    assert {:ok, _querry} = Api.get(id)
    TestHelpers.cleanup_temp_files()
  end

  test "Insert 10 cyphers and decrypt them", %{msg: msg, test_user: test_user} do
    path = create_file(msg)

    for _item <- 1..10//1 do
      assert {:ok, _querry} = Context.cypher_insert(path, test_user, "key")
    end

    assert {:ok, querry} = Context.decrypt_all(test_user, "key", memory: true)

    # The new system returns blob directly when memory: true
    assert %{name: name, blob: blob} = List.first(querry)
    assert ^msg = blob
    assert ^name = Path.basename(path, Path.extname(path))

    TestHelpers.cleanup_temp_files()
  end

  test "Insert an data, then update its content.", %{msg: msg, test_user: test_user} do
    path = create_file(msg)

    assert {:ok, id} = Context.cypher_insert(path, test_user, "key")
    assert {:ok, data} = Context.decrypt_one(test_user, id, "key")
    # Read the file content from the path
    blob = File.read!(data.path)

    assert {:ok, _querry} =
             Context.cypher_update(
               test_user,
               id,
               %{name: data.name <> data.ext, blob: blob},
               "key"
             )

    TestHelpers.cleanup_temp_files()
  end

  test "Insert 10 groups, then remove them.", %{test_user: test_user} do
    id_list =
      for item <- 1..10//1 do
        Context.group_insert("Group#{item}", test_user, "key")
      end

    for {:ok, id} <- id_list do
      assert {:ok, _querry} = Context.group_delete(test_user, id, "key")
    end
  end

  test "2 forms to update a group.", %{test_user: test_user} do
    assert {:ok, group_id} = Context.group_insert("Group0", test_user, "key")
    assert {:ok, id} = Context.group_insert("Group1", test_user, "key")

    assert {:ok, _querry} = Context.group_update(test_user, id, %{name: "Group2"}, "key")
    assert {:ok, _querry} = Context.group_update(test_user, id, %{group_id: group_id}, "key")
  end

  test "Duplicate a cypher, and a group", %{msg: msg, test_user: test_user} do
    path = create_file(msg)

    assert {:ok, data_id} = Context.cypher_insert(path, test_user, "key")
    assert {:ok, main_id} = Context.group_insert("Main", test_user, "key")
    assert {:ok, group_id} = Context.group_insert("Group1", test_user, "key")

    assert {:ok, _id} = Context.cypher_duplicate(test_user, data_id, %{group_id: main_id}, "key")
    assert {:ok, _id} = Context.group_duplicate(test_user, group_id, %{group_id: main_id}, "key")

    TestHelpers.cleanup_temp_files()
  end

  test "Insert 5 cyphers and 5 groups, then check your size", %{msg: msg, test_user: test_user} do
    path = create_file(msg)

    for item <- 1..5//1 do
      assert {:ok, _querry} = Context.cypher_insert(path, test_user, "key")
      assert {:ok, _querry} = Context.group_insert("Group#{item}", test_user, "key")
    end

    assert {:ok, querry} = Context.decrypt_all(test_user, "key", lazy: true)
    assert 10 = length(querry)

    TestHelpers.cleanup_temp_files()
  end

  test "Delete all cyphers", %{msg: msg, test_user: test_user} do
    path = create_file(msg)

    for item <- 1..5//1 do
      Context.cypher_insert(path, test_user, "key")
      Context.group_insert("Group#{item}", test_user, "key")
    end

    assert {:ok, 10} = Context.delete_all(test_user, "key")

    TestHelpers.cleanup_temp_files()
  end

  # test "Update all cyphers", %{msg: msg} do
  #   path = create_file(msg)

  #   for item <- 1..5//1 do
  #     Context.cypher_insert(path, @test_user, "key")
  #     Context.group_insert("Group#{item}", @test_user, "key")
  #   end

  #   assert {:ok, 10} = Context.update_all(@test_user, "key", "lock")
  #   assert {:error, "invalid key"} = Context.update_all(@test_user, "other_key", "key")
  #   assert {:ok, 10} = Context.update_all(@test_user, "lock", "key")

  TestHelpers.cleanup_temp_files()
end
