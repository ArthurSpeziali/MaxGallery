defmodule MaxGallery.GroupDuplicateBugTest do
  use MaxGallery.DataCase
  alias MaxGallery.Context
  alias MaxGallery.TestHelpers

  setup do
    # Ensure storage mock is started
    MaxGallery.Storage.Mock.start_link()
    
    {:ok, msg: "Test file content for group duplication bug test"}
  end

  defp create_file(msg) do
    TestHelpers.create_temp_file(msg)
  end

  test "group duplication bug: folder with 2+ items including subfolders", %{msg: msg} do
    # Create a test user
    test_user = TestHelpers.create_real_test_user()
    path = create_file(msg)

    # Create the problematic structure:
    # Parent Group
    # ├── File 1
    # └── Child Group
    #     └── File 2

    # Create parent group
    assert {:ok, parent_id} = Context.group_insert("Parent", test_user, "key")
    
    # Create File 1 in parent group
    assert {:ok, _file1_id} = Context.cypher_insert(path, test_user, "key", group: parent_id, name: "file1.txt")
    
    # Create Child Group inside parent
    assert {:ok, child_id} = Context.group_insert("Child", test_user, "key", group: parent_id)
    
    # Create File 2 in child group
    assert {:ok, _file2_id} = Context.cypher_insert(path, test_user, "key", group: child_id, name: "file2.txt")

    # Verify the structure before duplication
    assert {:ok, parent_contents} = Context.decrypt_all(test_user, "key", group: parent_id, lazy: true)
    assert length(parent_contents) == 2  # 1 file + 1 group
    
    # Find the child group and file
    file1 = Enum.find(parent_contents, fn item -> Map.has_key?(item, :ext) && item.name == "file1" end)
    child_group = Enum.find(parent_contents, fn item -> !Map.has_key?(item, :ext) && item.name == "Child" end)
    
    assert file1 != nil
    assert child_group != nil
    
    # Verify child group has content
    assert {:ok, child_contents} = Context.decrypt_all(test_user, "key", group: child_group.id, lazy: true)
    assert length(child_contents) == 1
    
    file2 = List.first(child_contents)
    assert file2.name == "file2"
    assert Map.has_key?(file2, :ext)  # Should be a file, not a group

    # Now duplicate the parent group - this should trigger the bug
    assert {:ok, new_parent_id} = Context.group_duplicate(test_user, parent_id, %{group_id: nil}, "key")

    # Verify the duplicated structure
    assert {:ok, new_parent_contents} = Context.decrypt_all(test_user, "key", group: new_parent_id, lazy: true)
    assert length(new_parent_contents) == 2  # Should still be 1 file + 1 group
    
    # Find the duplicated items
    new_file1 = Enum.find(new_parent_contents, fn item -> Map.has_key?(item, :ext) && item.name == "file1" end)
    new_child_group = Enum.find(new_parent_contents, fn item -> !Map.has_key?(item, :ext) && item.name == "Child" end)
    
    assert new_file1 != nil
    assert new_child_group != nil
    
    # The bug: child group should still be a group, not treated as a file
    assert !Map.has_key?(new_child_group, :ext), "Child group should not have :ext field (should not be treated as file)"
    
    # Verify the child group's contents
    assert {:ok, new_child_contents} = Context.decrypt_all(test_user, "key", group: new_child_group.id, lazy: true)
    assert length(new_child_contents) == 1
    
    new_file2 = List.first(new_child_contents)
    assert new_file2.name == "file2"
    assert Map.has_key?(new_file2, :ext)  # Should be a file

    TestHelpers.cleanup_temp_files()
  end
end