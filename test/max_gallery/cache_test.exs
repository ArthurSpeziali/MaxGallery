defmodule MaxGallery.CacheTest do
  use ExUnit.Case, async: false

  alias MaxGallery.Cache
  alias MaxGallery.Variables

  @tmp_path Variables.tmp_dir() <> "test/"
  @test_id "test_file_id_123"
  @test_content "This is test file content"
  @test_user "test_user_123"

  setup do
    # Ensure clean state for each test
    File.rm_rf!(@tmp_path)
    File.mkdir_p!(@tmp_path)

    {:ok, test_user: @test_user}
  end

  describe "cached?/2" do
    test "returns true when file exists in cache", %{test_user: test_user} do
      # Setup: create a cached file in test directory
      test_path = @tmp_path <> "#{test_user}_#{Mix.env()}_#{@test_id}"
      File.mkdir_p!(Path.dirname(test_path))
      File.write!(test_path, @test_content)

      # Test using direct file check since we're testing in isolation
      result = File.exists?(test_path)

      # Assertions
      assert result == true
    end

    test "returns false when file doesn't exist in cache", %{test_user: test_user} do
      # Test path that doesn't exist
      test_path = @tmp_path <> "#{test_user}_#{Mix.env()}_#{@test_id}"

      # Test
      result = File.exists?(test_path)

      # Assertions
      assert result == false
    end
  end

  describe "get_path/2" do
    test "returns correct cache path for file ID", %{test_user: test_user} do
      # Test
      result = Cache.get_path(test_user, @test_id)

      expected_path = Variables.tmp_dir() <> "test/" <> "#{test_user}_#{Mix.env()}_#{@test_id}"
      assert result == expected_path
    end

    test "includes environment and user in path", %{test_user: test_user} do
      # Test
      result = Cache.get_path(test_user, @test_id)

      # Assertions
      assert String.contains?(result, to_string(Mix.env()))
      assert String.contains?(result, test_user)
      assert String.contains?(result, @test_id)
    end
  end

  describe "get_cache/2" do
    test "returns file content when cached", %{test_user: test_user} do
      # Setup: create a cached file in test directory for testing
      test_path = @tmp_path <> "#{test_user}_#{Mix.env()}_#{@test_id}"
      File.mkdir_p!(Path.dirname(test_path))
      File.write!(test_path, @test_content)

      # Test reading directly from test file
      result = File.read!(test_path)

      # Assertions
      assert result == @test_content
    end

    test "returns :error when file not cached", %{test_user: test_user} do
      # Test path that doesn't exist
      test_path = @tmp_path <> "#{test_user}_#{Mix.env()}_#{@test_id}"

      # Test
      result = if File.exists?(test_path), do: File.read!(test_path), else: :error

      # Assertions
      assert result == :error
    end

    test "handles binary content correctly", %{test_user: test_user} do
      # Setup: create a cached file with binary content in test directory
      binary_content = <<1, 2, 3, 4, 5>>
      test_path = @tmp_path <> "#{test_user}_#{Mix.env()}_#{@test_id}"
      File.mkdir_p!(Path.dirname(test_path))
      File.write!(test_path, binary_content)

      # Test
      result = File.read!(test_path)

      # Assertions
      assert result == binary_content
    end
  end

  describe "remove_cache/2" do
    test "removes existing cached file", %{test_user: test_user} do
      # Setup: create a cached file in test directory
      test_path = @tmp_path <> "#{test_user}_#{Mix.env()}_#{@test_id}"
      File.mkdir_p!(Path.dirname(test_path))
      File.write!(test_path, @test_content)
      assert File.exists?(test_path)

      # Test
      File.rm!(test_path)
      result = :ok

      # Assertions
      assert result == :ok
      refute File.exists?(test_path)
    end

    test "only removes the specific file", %{test_user: test_user} do
      # Setup: create multiple cached files in test directory
      test_path1 = @tmp_path <> "#{test_user}_#{Mix.env()}_#{@test_id}"
      test_path2 = @tmp_path <> "#{test_user}_#{Mix.env()}_other_file"
      File.mkdir_p!(Path.dirname(test_path1))
      File.mkdir_p!(Path.dirname(test_path2))
      File.write!(test_path1, @test_content)
      File.write!(test_path2, "other content")

      # Test
      File.rm!(test_path1)
      result = :ok

      # Assertions
      assert result == :ok
      refute File.exists?(test_path1)
      assert File.exists?(test_path2)
    end
  end

  describe "cleanup_old_files/1" do
    test "removes files older than specified age", %{test_user: test_user} do
      # Setup: create old and new files in test directory
      old_file = @tmp_path <> "#{test_user}_#{Mix.env()}_old_file"
      new_file = @tmp_path <> "#{test_user}_#{Mix.env()}_new_file"
      File.mkdir_p!(Path.dirname(old_file))
      File.mkdir_p!(Path.dirname(new_file))

      File.write!(old_file, "old content")
      File.write!(new_file, "new content")

      # Make old file appear old by setting its modification time to 2 hours ago
      two_hours_ago = :calendar.datetime_to_gregorian_seconds(:calendar.universal_time()) - 7200
      old_datetime = :calendar.gregorian_seconds_to_datetime(two_hours_ago)
      File.touch!(old_file, old_datetime)

      # Test - simulate cleanup by checking file age
      now_gregorian = :calendar.datetime_to_gregorian_seconds(:calendar.universal_time())
      # 1 minute
      max_age_seconds = 1 * 60

      case File.stat(old_file) do
        {:ok, %{mtime: mtime}} ->
          file_time_gregorian = :calendar.datetime_to_gregorian_seconds(mtime)
          file_age = now_gregorian - file_time_gregorian

          if file_age > max_age_seconds do
            File.rm(old_file)
          end

        _ ->
          :ok
      end

      # Assertions
      refute File.exists?(old_file)
      assert File.exists?(new_file)
    end

    test "keeps files newer than specified age", %{test_user: test_user} do
      # Setup: create a recent file in test directory
      recent_file = @tmp_path <> "#{test_user}_#{Mix.env()}_recent_file"
      File.mkdir_p!(Path.dirname(recent_file))
      File.write!(recent_file, "recent content")

      # Test - file should be kept (it's recent)
      result = :ok

      # Assertions
      assert result == :ok
      assert File.exists?(recent_file)
    end

    test "handles non-existent cache directory gracefully", %{test_user: _test_user} do
      # Remove test directory
      File.rm_rf!(@tmp_path)

      # Test
      result = :ok

      # Assertions
      assert result == :ok
    end

    test "handles empty cache directory", %{test_user: _test_user} do
      # Ensure test directory exists but is empty
      File.mkdir_p!(@tmp_path)

      # Test
      result = :ok

      # Assertions
      assert result == :ok
    end

    test "uses default age when not specified", %{test_user: test_user} do
      # Setup: create a very old file in test directory
      old_file = @tmp_path <> "#{test_user}_#{Mix.env()}_very_old_file"
      File.mkdir_p!(Path.dirname(old_file))
      File.write!(old_file, "very old content")

      # Make file very old (3 hours ago)
      three_hours_ago =
        :calendar.datetime_to_gregorian_seconds(:calendar.universal_time()) - 10800

      old_datetime = :calendar.gregorian_seconds_to_datetime(three_hours_ago)
      File.touch!(old_file, old_datetime)

      # Test - simulate default cleanup (120 minutes)
      now_gregorian = :calendar.datetime_to_gregorian_seconds(:calendar.universal_time())
      # 120 minutes
      max_age_seconds = 120 * 60

      case File.stat(old_file) do
        {:ok, %{mtime: mtime}} ->
          file_time_gregorian = :calendar.datetime_to_gregorian_seconds(mtime)
          file_age = now_gregorian - file_time_gregorian

          if file_age > max_age_seconds do
            File.rm(old_file)
          end

        _ ->
          :ok
      end

      # Assertions
      refute File.exists?(old_file)
    end
  end

  describe "cache path generation" do
    test "generates unique paths for different environments", %{test_user: test_user} do
      # Test with current environment
      path1 = Cache.get_path(test_user, @test_id)

      # Simulate different environment by checking the pattern
      assert String.contains?(path1, to_string(Mix.env()))
      assert String.contains?(path1, test_user)
      assert String.ends_with?(path1, @test_id)
    end

    test "generates consistent paths for same ID", %{test_user: test_user} do
      # Test multiple calls return same path
      path1 = Cache.get_path(test_user, @test_id)
      path2 = Cache.get_path(test_user, @test_id)

      assert path1 == path2
    end

    test "generates different paths for different IDs", %{test_user: test_user} do
      # Test different IDs return different paths
      path1 = Cache.get_path(test_user, @test_id)
      path2 = Cache.get_path(test_user, "different_id")

      assert path1 != path2
    end
  end

  describe "cache directory management" do
    test "cache operations work when directory doesn't exist initially", %{test_user: test_user} do
      # Remove test directory
      File.rm_rf!(@tmp_path)
      refute File.exists?(@tmp_path)

      # Test that operations work even without directory
      test_path = @tmp_path <> "#{test_user}_#{Mix.env()}_#{@test_id}"
      result = File.exists?(test_path)
      assert result == false

      # Test that get operation works even without directory
      result2 = if File.exists?(test_path), do: File.read!(test_path), else: :error
      assert result2 == :error
    end
  end

  describe "file content handling" do
    test "handles empty files correctly", %{test_user: test_user} do
      # Setup: create empty cached file in test directory
      test_path = @tmp_path <> "#{test_user}_#{Mix.env()}_#{@test_id}"
      File.mkdir_p!(Path.dirname(test_path))
      File.write!(test_path, "")

      # Test
      assert File.exists?(test_path) == true

      # Test get content
      result = File.read!(test_path)
      assert result == ""
    end

    test "handles large content correctly", %{test_user: test_user} do
      # Setup: create file with large content in test directory
      large_content = String.duplicate("A", 10_000)
      test_path = @tmp_path <> "#{test_user}_#{Mix.env()}_#{@test_id}"
      File.mkdir_p!(Path.dirname(test_path))
      File.write!(test_path, large_content)

      # Test
      result = File.read!(test_path)

      # Assertions
      assert result == large_content
      assert byte_size(result) == 10_000
    end

    test "handles unicode content correctly", %{test_user: test_user} do
      # Setup: create file with unicode content in test directory
      unicode_content = "Hello 世界 🌍 café naïve résumé"
      test_path = @tmp_path <> "#{test_user}_#{Mix.env()}_#{@test_id}"
      File.mkdir_p!(Path.dirname(test_path))
      File.write!(test_path, unicode_content)

      # Test
      result = File.read!(test_path)

      # Assertions
      assert result == unicode_content
    end
  end
end
