defmodule MaxGallery.Storage.MockTest do
  use ExUnit.Case, async: false
  alias MaxGallery.Storage.Mock

  @test_user "test_user_123"

  setup do
    Mock.clear()
    {:ok, test_user: @test_user}
  end

  describe "Storage Mock" do
    test "put and get operations work correctly", %{test_user: test_user} do
      blob = "test content"
      cypher_id = "test_id_123"

      # Test put
      assert {:ok, _key} = Mock.put(test_user, cypher_id, blob)

      # Test get
      assert {:ok, ^blob} = Mock.get(test_user, cypher_id)
    end

    test "get returns error for non-existent file", %{test_user: test_user} do
      assert {:error, "File not found"} = Mock.get(test_user, "non_existent_id")
    end

    test "exists? works correctly", %{test_user: test_user} do
      cypher_id = "test_id_456"
      blob = "test content"

      # Should not exist initially
      refute Mock.exists?(test_user, cypher_id)

      # Should exist after put
      Mock.put(test_user, cypher_id, blob)
      assert Mock.exists?(test_user, cypher_id)
    end

    test "del removes files correctly", %{test_user: test_user} do
      cypher_id = "test_id_789"
      blob = "test content"

      # Put and verify exists
      Mock.put(test_user, cypher_id, blob)
      assert Mock.exists?(test_user, cypher_id)

      # Delete and verify doesn't exist
      assert :ok = Mock.del(test_user, cypher_id)
      refute Mock.exists?(test_user, cypher_id)
    end

    test "del_all removes all files", %{test_user: test_user} do
      # Put multiple files
      Mock.put(test_user, "id1", "content1")
      Mock.put(test_user, "id2", "content2")
      Mock.put(test_user, "id3", "content3")

      # Verify they exist
      assert Mock.exists?(test_user, "id1")
      assert Mock.exists?(test_user, "id2")
      assert Mock.exists?(test_user, "id3")

      # Delete all
      assert {:ok, 3} = Mock.del_all(test_user)

      # Verify none exist
      refute Mock.exists?(test_user, "id1")
      refute Mock.exists?(test_user, "id2")
      refute Mock.exists?(test_user, "id3")
    end

    test "list returns file metadata", %{test_user: test_user} do
      blob1 = "content1"
      blob2 = "content2"

      Mock.put(test_user, "id1", blob1)
      Mock.put(test_user, "id2", blob2)

      assert {:ok, files} = Mock.list(test_user)
      assert length(files) == 2

      # Check that files contain expected metadata
      file_names = Enum.map(files, & &1.file_name)
      assert "encrypted_files/#{test_user}/id1" in file_names
      assert "encrypted_files/#{test_user}/id2" in file_names
    end

    test "clear resets the mock state", %{test_user: test_user} do
      Mock.put(test_user, "id1", "content1")
      Mock.put(test_user, "id2", "content2")

      assert Mock.exists?(test_user, "id1")
      assert Mock.exists?(test_user, "id2")

      Mock.clear()

      refute Mock.exists?(test_user, "id1")
      refute Mock.exists?(test_user, "id2")
    end
  end
end
