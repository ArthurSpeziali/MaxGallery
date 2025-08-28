defmodule MaxGallery.GroupDuplicateComprehensiveTest do
  use MaxGallery.DataCase
  alias MaxGallery.Context
  alias MaxGallery.TestHelpers

  setup do
    # Ensure storage mock is started
    MaxGallery.Storage.Mock.start_link()
    
    {:ok, msg: "Test file content for comprehensive group duplication test"}
  end

  defp create_file(msg) do
    TestHelpers.create_temp_file(msg)
  end

  test "comprehensive group duplication with complex hierarchy", %{msg: msg} do
    # Create a test user
    test_user = TestHelpers.create_real_test_user()
    path = create_file(msg)

    # Create a complex structure:
    # Root
    # ├── file1.txt
    # ├── SubA
    # │   ├── file2.txt
    # │   └── SubB
    # │       ├── file3.txt
    # │       └── file4.txt
    # └── SubC
    #     └── file5.txt

    # Create root group
    assert {:ok, root_id} = Context.group_insert("Root", test_user, "key")
    
    # Create file1.txt in root
    assert {:ok, _file1_id} = Context.cypher_insert(path, test_user, "key", group: root_id, name: "file1.txt")
    
    # Create SubA
    assert {:ok, sub_a_id} = Context.group_insert("SubA", test_user, "key", group: root_id)
    
    # Create file2.txt in SubA
    assert {:ok, _file2_id} = Context.cypher_insert(path, test_user, "key", group: sub_a_id, name: "file2.txt")
    
    # Create SubB inside SubA
    assert {:ok, sub_b_id} = Context.group_insert("SubB", test_user, "key", group: sub_a_id)
    
    # Create file3.txt and file4.txt in SubB
    assert {:ok, _file3_id} = Context.cypher_insert(path, test_user, "key", group: sub_b_id, name: "file3.txt")
    assert {:ok, _file4_id} = Context.cypher_insert(path, test_user, "key", group: sub_b_id, name: "file4.txt")
    
    # Create SubC in root
    assert {:ok, sub_c_id} = Context.group_insert("SubC", test_user, "key", group: root_id)
    
    # Create file5.txt in SubC
    assert {:ok, _file5_id} = Context.cypher_insert(path, test_user, "key", group: sub_c_id, name: "file5.txt")

    # Verify the original structure
    assert {:ok, root_contents} = Context.decrypt_all(test_user, "key", group: root_id, lazy: true)
    assert length(root_contents) == 3  # 1 file + 2 groups

    # Duplicate the root group
    assert {:ok, new_root_id} = Context.group_duplicate(test_user, root_id, %{group_id: nil}, "key")

    # Verify the duplicated structure
    assert {:ok, new_root_contents} = Context.decrypt_all(test_user, "key", group: new_root_id, lazy: true)
    assert length(new_root_contents) == 3  # Should still be 1 file + 2 groups
    
    # Find duplicated items
    new_file1 = Enum.find(new_root_contents, fn item -> Map.has_key?(item, :ext) && item.name == "file1" end)
    new_sub_a = Enum.find(new_root_contents, fn item -> !Map.has_key?(item, :ext) && item.name == "SubA" end)
    new_sub_c = Enum.find(new_root_contents, fn item -> !Map.has_key?(item, :ext) && item.name == "SubC" end)
    
    assert new_file1 != nil
    assert new_sub_a != nil
    assert new_sub_c != nil
    
    # Verify SubA contents
    assert {:ok, new_sub_a_contents} = Context.decrypt_all(test_user, "key", group: new_sub_a.id, lazy: true)
    assert length(new_sub_a_contents) == 2  # 1 file + 1 group
    
    new_file2 = Enum.find(new_sub_a_contents, fn item -> Map.has_key?(item, :ext) && item.name == "file2" end)
    new_sub_b = Enum.find(new_sub_a_contents, fn item -> !Map.has_key?(item, :ext) && item.name == "SubB" end)
    
    assert new_file2 != nil
    assert new_sub_b != nil
    
    # Verify SubB contents (deepest level)
    assert {:ok, new_sub_b_contents} = Context.decrypt_all(test_user, "key", group: new_sub_b.id, lazy: true)
    assert length(new_sub_b_contents) == 2  # 2 files
    
    new_file3 = Enum.find(new_sub_b_contents, fn item -> item.name == "file3" end)
    new_file4 = Enum.find(new_sub_b_contents, fn item -> item.name == "file4" end)
    
    assert new_file3 != nil
    assert new_file4 != nil
    assert Map.has_key?(new_file3, :ext)  # Should be files, not groups
    assert Map.has_key?(new_file4, :ext)  # Should be files, not groups
    
    # Verify SubC contents
    assert {:ok, new_sub_c_contents} = Context.decrypt_all(test_user, "key", group: new_sub_c.id, lazy: true)
    assert length(new_sub_c_contents) == 1  # 1 file
    
    new_file5 = List.first(new_sub_c_contents)
    assert new_file5.name == "file5"
    assert Map.has_key?(new_file5, :ext)  # Should be a file, not a group

    # Verify all items have different IDs (are actually duplicated)
    assert new_file1.id != _file1_id
    assert new_file2.id != _file2_id
    assert new_file3.id != _file3_id
    assert new_file4.id != _file4_id
    assert new_file5.id != _file5_id
    
    assert new_sub_a.id != sub_a_id
    assert new_sub_b.id != sub_b_id
    assert new_sub_c.id != sub_c_id

    TestHelpers.cleanup_temp_files()
  end
end