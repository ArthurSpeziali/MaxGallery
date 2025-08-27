defmodule MaxGallery.Storage.MockTest do
  use ExUnit.Case, async: false
  alias MaxGallery.Storage.Mock

  setup do
    Mock.clear()
    :ok
  end

  describe "Storage Mock" do
    test "put and get operations work correctly" do
      blob = "test content"
      cypher_id = "test_id_123"

      # Test put
      assert {:ok, _key} = Mock.put(cypher_id, blob)

      # Test get
      assert {:ok, ^blob} = Mock.get(cypher_id)
    end

    test "get returns error for non-existent file" do
      assert {:error, "File not found"} = Mock.get("non_existent_id")
    end

    test "exists? works correctly" do
      cypher_id = "test_id_456"
      blob = "test content"

      # Should not exist initially
      refute Mock.exists?(cypher_id)

      # Should exist after put
      Mock.put(cypher_id, blob)
      assert Mock.exists?(cypher_id)
    end

    test "del removes files correctly" do
      cypher_id = "test_id_789"
      blob = "test content"

      # Put and verify exists
      Mock.put(cypher_id, blob)
      assert Mock.exists?(cypher_id)

      # Delete and verify doesn't exist
      assert :ok = Mock.del(cypher_id)
      refute Mock.exists?(cypher_id)
    end

    test "del_all removes all files" do
      # Put multiple files
      Mock.put("id1", "content1")
      Mock.put("id2", "content2")
      Mock.put("id3", "content3")

      # Verify they exist
      assert Mock.exists?("id1")
      assert Mock.exists?("id2")
      assert Mock.exists?("id3")

      # Delete all
      assert {:ok, 3} = Mock.del_all()

      # Verify none exist
      refute Mock.exists?("id1")
      refute Mock.exists?("id2")
      refute Mock.exists?("id3")
    end

    test "list returns file metadata" do
      blob1 = "content1"
      blob2 = "content2"
      
      Mock.put("id1", blob1)
      Mock.put("id2", blob2)

      assert {:ok, files} = Mock.list()
      assert length(files) == 2

      # Check that files contain expected metadata
      file_names = Enum.map(files, & &1.file_name)
      assert "encrypted_files/id1" in file_names
      assert "encrypted_files/id2" in file_names
    end

    test "clear resets the mock state" do
      Mock.put("id1", "content1")
      Mock.put("id2", "content2")

      assert Mock.exists?("id1")
      assert Mock.exists?("id2")

      Mock.clear()

      refute Mock.exists?("id1")
      refute Mock.exists?("id2")
    end
  end
end