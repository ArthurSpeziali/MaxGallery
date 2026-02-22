defmodule MaxGallery.Storage.MockTest do
  use ExUnit.Case, async: true
  alias MaxGallery.Storage.Mock

  setup do
    # Ensure mock is started and cleared before each test
    Mock.start_link()
    Mock.clear()
    :ok
  end

  describe "put/3 and get/2" do
    test "stores and retrieves binary data" do
      user = "test_user"
      id = 123
      blob = "Hello, World!"

      # Store data
      assert :ok = Mock.put(user, id, blob)

      # Retrieve data
      assert {:ok, retrieved_blob} = Mock.get(user, id)
      assert retrieved_blob == blob
    end

    test "handles binary data" do
      user = "test_user"
      id = 456
      blob = <<1, 2, 3, 255, 0, 128>>

      assert :ok = Mock.put(user, id, blob)
      assert {:ok, retrieved_blob} = Mock.get(user, id)
      assert retrieved_blob == blob
    end

    test "handles empty data" do
      user = "test_user"
      id = 789
      blob = ""

      assert :ok = Mock.put(user, id, blob)
      assert {:ok, retrieved_blob} = Mock.get(user, id)
      assert retrieved_blob == blob
    end

    test "handles large data" do
      user = "test_user"
      id = 999
      blob = String.duplicate("Large data chunk. ", 1000)

      assert :ok = Mock.put(user, id, blob)
      assert {:ok, retrieved_blob} = Mock.get(user, id)
      assert retrieved_blob == blob
    end

    test "returns error for non-existent file" do
      user = "test_user"
      id = 404

      assert {:error, "File not found"} = Mock.get(user, id)
    end

    test "isolates data by user" do
      user1 = "user1"
      user2 = "user2"
      id = 123
      blob1 = "User 1 data"
      blob2 = "User 2 data"

      # Store data for both users with same ID
      assert :ok = Mock.put(user1, id, blob1)
      assert :ok = Mock.put(user2, id, blob2)

      # Retrieve data - should be isolated
      assert {:ok, retrieved1} = Mock.get(user1, id)
      assert {:ok, retrieved2} = Mock.get(user2, id)

      assert retrieved1 == blob1
      assert retrieved2 == blob2
    end

    test "overwrites existing data" do
      user = "test_user"
      id = 123
      original_blob = "Original data"
      new_blob = "Updated data"

      # Store original data
      assert :ok = Mock.put(user, id, original_blob)
      assert {:ok, retrieved} = Mock.get(user, id)
      assert retrieved == original_blob

      # Overwrite with new data
      assert :ok = Mock.put(user, id, new_blob)
      assert {:ok, retrieved} = Mock.get(user, id)
      assert retrieved == new_blob
    end
  end

  describe "put_stream/3 and get_stream/2" do
    test "stores and retrieves stream data" do
      user = "test_user"
      id = 123
      data_chunks = ["chunk1", "chunk2", "chunk3"]
      stream = Stream.map(data_chunks, & &1)

      # Store stream
      assert :ok = Mock.put_stream(user, id, stream)

      # Retrieve as stream
      assert {:ok, retrieved_stream} = Mock.get_stream(user, id)
      retrieved_chunks = Enum.to_list(retrieved_stream)
      retrieved_data = Enum.join(retrieved_chunks, "")

      expected_data = Enum.join(data_chunks, "")
      assert retrieved_data == expected_data
    end

    test "handles large stream data" do
      user = "test_user"
      id = 456
      large_chunk = String.duplicate("X", 10_000)
      data_chunks = [large_chunk, large_chunk, large_chunk]
      stream = Stream.map(data_chunks, & &1)

      assert :ok = Mock.put_stream(user, id, stream)

      assert {:ok, retrieved_stream} = Mock.get_stream(user, id)
      retrieved_data = Enum.join(retrieved_stream, "")
      expected_data = Enum.join(data_chunks, "")

      assert retrieved_data == expected_data
    end

    test "handles empty stream" do
      user = "test_user"
      id = 789
      stream = Stream.map([], & &1)

      assert :ok = Mock.put_stream(user, id, stream)

      assert {:ok, retrieved_stream} = Mock.get_stream(user, id)
      retrieved_data = Enum.join(retrieved_stream, "")

      assert retrieved_data == ""
    end

    test "returns error for non-existent stream" do
      user = "test_user"
      id = 404

      assert {:error, "File not found"} = Mock.get_stream(user, id)
    end

    test "chunks data appropriately" do
      user = "test_user"
      id = 123
      # Create data larger than chunk size (8KB)
      large_data = String.duplicate("A", 20_000)
      stream = Stream.map([large_data], & &1)

      assert :ok = Mock.put_stream(user, id, stream)

      assert {:ok, retrieved_stream} = Mock.get_stream(user, id)
      chunks = Enum.to_list(retrieved_stream)

      # Should have multiple chunks
      assert length(chunks) > 1

      # Reassembled data should match original
      reassembled = Enum.join(chunks, "")
      assert reassembled == large_data

      # Most chunks should be 8KB (except possibly the last one)
      chunk_sizes = Enum.map(chunks, &byte_size/1)
      most_chunks = Enum.drop(chunk_sizes, -1)
      assert Enum.all?(most_chunks, &(&1 == 8192))
    end
  end

  describe "get_stream/3 (to file)" do
    test "writes stream to file" do
      user = "test_user"
      id = 123
      data = "Stream data to write to file"
      stream = Stream.map([data], & &1)

      # Store stream
      assert :ok = Mock.put_stream(user, id, stream)

      # Write to temporary file
      temp_path = System.tmp_dir!() <> "/mock_test_#{:rand.uniform(1000)}.txt"

      on_exit(fn ->
        if File.exists?(temp_path), do: File.rm!(temp_path)
      end)

      assert :ok = Mock.get_stream(user, id, temp_path)

      # Verify file contents
      assert File.exists?(temp_path)
      file_contents = File.read!(temp_path)
      assert file_contents == data
    end

    test "handles large stream to file" do
      user = "test_user"
      id = 456
      large_data = String.duplicate("Large stream data. ", 1000)
      stream = Stream.map([large_data], & &1)

      assert :ok = Mock.put_stream(user, id, stream)

      temp_path = System.tmp_dir!() <> "/large_mock_test_#{:rand.uniform(1000)}.txt"

      on_exit(fn ->
        if File.exists?(temp_path), do: File.rm!(temp_path)
      end)

      assert :ok = Mock.get_stream(user, id, temp_path)

      file_contents = File.read!(temp_path)
      assert file_contents == large_data
    end

    test "returns error for non-existent file" do
      user = "test_user"
      id = 404
      temp_path = System.tmp_dir!() <> "/nonexistent_test.txt"

      result = Mock.get_stream(user, id, temp_path)
      assert {:error, "File not found"} = result
    end
  end

  describe "del/2" do
    test "deletes existing file" do
      user = "test_user"
      id = 123
      blob = "Data to delete"

      # Store data
      assert :ok = Mock.put(user, id, blob)
      assert {:ok, _} = Mock.get(user, id)

      # Delete data
      assert :ok = Mock.del(user, id)

      # Verify deletion
      assert {:error, "File not found"} = Mock.get(user, id)
    end

    test "deleting non-existent file succeeds" do
      user = "test_user"
      id = 404

      # Should not error even if file doesn't exist
      assert :ok = Mock.del(user, id)
    end

    test "deletion is isolated by user" do
      user1 = "user1"
      user2 = "user2"
      id = 123
      blob1 = "User 1 data"
      blob2 = "User 2 data"

      # Store data for both users
      assert :ok = Mock.put(user1, id, blob1)
      assert :ok = Mock.put(user2, id, blob2)

      # Delete user1's data
      assert :ok = Mock.del(user1, id)

      # Verify user1's data is gone, user2's remains
      assert {:error, "File not found"} = Mock.get(user1, id)
      assert {:ok, retrieved} = Mock.get(user2, id)
      assert retrieved == blob2
    end
  end

  describe "del_all/1" do
    test "deletes all files for a user" do
      user = "test_user"
      
      # Store multiple files
      assert :ok = Mock.put(user, 1, "File 1")
      assert :ok = Mock.put(user, 2, "File 2")
      assert :ok = Mock.put(user, 3, "File 3")

      # Verify files exist
      assert {:ok, _} = Mock.get(user, 1)
      assert {:ok, _} = Mock.get(user, 2)
      assert {:ok, _} = Mock.get(user, 3)

      # Delete all files for user
      assert :ok = Mock.del_all(user)

      # Verify all files are gone
      assert {:error, "File not found"} = Mock.get(user, 1)
      assert {:error, "File not found"} = Mock.get(user, 2)
      assert {:error, "File not found"} = Mock.get(user, 3)
    end

    test "deletion is isolated by user" do
      user1 = "user1"
      user2 = "user2"

      # Store files for both users
      assert :ok = Mock.put(user1, 1, "User 1 File 1")
      assert :ok = Mock.put(user1, 2, "User 1 File 2")
      assert :ok = Mock.put(user2, 1, "User 2 File 1")
      assert :ok = Mock.put(user2, 2, "User 2 File 2")

      # Delete all files for user1
      assert :ok = Mock.del_all(user1)

      # Verify user1's files are gone, user2's remain
      assert {:error, "File not found"} = Mock.get(user1, 1)
      assert {:error, "File not found"} = Mock.get(user1, 2)
      assert {:ok, _} = Mock.get(user2, 1)
      assert {:ok, _} = Mock.get(user2, 2)
    end

    test "deleting all files for non-existent user succeeds" do
      user = "non_existent_user"
      assert :ok = Mock.del_all(user)
    end
  end

  describe "exists?/2" do
    test "returns true for existing file" do
      user = "test_user"
      id = 123
      blob = "Existing file"

      assert :ok = Mock.put(user, id, blob)
      assert Mock.exists?(user, id) == true
    end

    test "returns false for non-existent file" do
      user = "test_user"
      id = 404

      assert Mock.exists?(user, id) == false
    end

    test "existence check is isolated by user" do
      user1 = "user1"
      user2 = "user2"
      id = 123

      # Store file for user1 only
      assert :ok = Mock.put(user1, id, "User 1 file")

      # Check existence
      assert Mock.exists?(user1, id) == true
      assert Mock.exists?(user2, id) == false
    end
  end

  describe "list/1" do
    test "lists files for user" do
      user = "test_user"

      # Store multiple files
      assert :ok = Mock.put(user, 1, "File 1 content")
      assert :ok = Mock.put(user, 2, "File 2 content with more data")
      assert :ok = Mock.put(user, 3, "")

      # List files
      {:ok, files} = Mock.list(user)

      assert length(files) == 3

      # Verify file structure
      for file <- files do
        assert Map.has_key?(file, :file_name)
        assert Map.has_key?(file, :file_id)
        assert Map.has_key?(file, :size)
        assert Map.has_key?(file, :content_type)
        assert Map.has_key?(file, :upload_timestamp)
        assert Map.has_key?(file, :content_sha1)
        assert Map.has_key?(file, :file_info)

        assert file.content_type == "application/octet-stream"
        assert is_integer(file.size)
        assert is_integer(file.upload_timestamp)
        assert is_binary(file.content_sha1)
      end

      # Verify sizes match content
      file_sizes = Enum.map(files, & &1.size)
      expected_sizes = [
        byte_size("File 1 content"),
        byte_size("File 2 content with more data"),
        byte_size("")
      ]

      assert Enum.sort(file_sizes) == Enum.sort(expected_sizes)
    end

    test "returns empty list for user with no files" do
      user = "empty_user"

      {:ok, files} = Mock.list(user)
      assert files == []
    end

    test "listing is isolated by user" do
      user1 = "user1"
      user2 = "user2"

      # Store files for both users
      assert :ok = Mock.put(user1, 1, "User 1 File")
      assert :ok = Mock.put(user1, 2, "User 1 File 2")
      assert :ok = Mock.put(user2, 1, "User 2 File")

      # List files for each user
      {:ok, user1_files} = Mock.list(user1)
      {:ok, user2_files} = Mock.list(user2)

      assert length(user1_files) == 2
      assert length(user2_files) == 1
    end

    test "SHA1 hashes are correct" do
      user = "test_user"
      content = "Test content for SHA1"

      assert :ok = Mock.put(user, 1, content)

      {:ok, files} = Mock.list(user)
      file = List.first(files)

      expected_sha1 = :crypto.hash(:sha, content) |> Base.encode16(case: :lower)
      assert file.content_sha1 == expected_sha1
    end
  end

  describe "clear/0" do
    test "clears all stored data" do
      user1 = "user1"
      user2 = "user2"

      # Store data for multiple users
      assert :ok = Mock.put(user1, 1, "User 1 data")
      assert :ok = Mock.put(user2, 1, "User 2 data")

      # Verify data exists
      assert {:ok, _} = Mock.get(user1, 1)
      assert {:ok, _} = Mock.get(user2, 1)

      # Clear all data
      Mock.clear()

      # Verify all data is gone
      assert {:error, "File not found"} = Mock.get(user1, 1)
      assert {:error, "File not found"} = Mock.get(user2, 1)
    end
  end

  describe "start_link/1 and stop/0" do
    test "can start and stop mock" do
      # Stop current instance
      Mock.stop()

      # Start new instance
      {:ok, pid} = Mock.start_link()
      assert is_pid(pid)
      assert Process.alive?(pid)

      # Verify it works
      assert :ok = Mock.put("test", 1, "test data")
      assert {:ok, "test data"} = Mock.get("test", 1)

      # Stop it
      Mock.stop()

      # Restart for other tests
      Mock.start_link()
    end

    test "handles multiple start attempts gracefully" do
      # Should not error if already started
      result = Mock.start_link()
      case result do
        {:ok, _pid} -> assert true
        {:error, {:already_started, _pid}} -> assert true
        other -> flunk("Unexpected result: #{inspect(other)}")
      end
    end
  end

  describe "integration with streams and files" do
    test "full stream workflow" do
      user = "stream_user"
      id = 999

      # Create test data as stream
      test_data = "Line 1\nLine 2\nLine 3\n"
      stream = Stream.map([test_data], & &1)

      # Store stream
      assert :ok = Mock.put_stream(user, id, stream)

      # Retrieve as stream and process
      assert {:ok, retrieved_stream} = Mock.get_stream(user, id)
      processed_data = 
        retrieved_stream
        |> Enum.to_list()
        |> Enum.join("")

      assert processed_data == test_data

      # Write to file
      temp_path = System.tmp_dir!() <> "/stream_integration_#{:rand.uniform(1000)}.txt"

      on_exit(fn ->
        if File.exists?(temp_path), do: File.rm!(temp_path)
      end)

      assert :ok = Mock.get_stream(user, id, temp_path)
      file_contents = File.read!(temp_path)
      assert file_contents == test_data

      # Verify file exists in listing
      {:ok, files} = Mock.list(user)
      assert length(files) == 1
      file = List.first(files)
      assert file.size == byte_size(test_data)

      # Clean up
      assert :ok = Mock.del(user, id)
      assert {:error, "File not found"} = Mock.get(user, id)
    end
  end
end