defmodule MaxGallery.CacheTest do
  use ExUnit.Case, async: false

  alias MaxGallery.Cache
  alias MaxGallery.Variables

  @tmp_path Variables.tmp_dir() <> "cache/"
  @test_id "test_file_id_123"
  @test_content "This is test file content"

  setup do
    # Ensure clean state for each test
    File.rm_rf!(@tmp_path)
    File.mkdir_p!(@tmp_path)

    :ok
  end

  describe "cached?/1" do
    test "returns true when file exists in cache" do
      # Setup: create a cached file
      test_path = @tmp_path <> "#{Mix.env()}_#{@test_id}"
      File.write!(test_path, @test_content)

      # Test
      result = Cache.cached?(@test_id)

      # Assertions
      assert result == true
    end

    test "returns false when file doesn't exist in cache" do
      # Test
      result = Cache.cached?(@test_id)

      # Assertions
      assert result == false
    end
  end

  describe "get_cache_path/1" do
    test "returns correct cache path for file ID" do
      # Test
      result = Cache.get_cache_path(@test_id)

      # Assertions
      expected_path = @tmp_path <> "#{Mix.env()}_#{@test_id}"
      assert result == expected_path
    end

    test "includes environment in path" do
      # Test
      result = Cache.get_cache_path(@test_id)

      # Assertions
      assert String.contains?(result, to_string(Mix.env()))
      assert String.contains?(result, @test_id)
    end
  end

  describe "get_cache/1" do
    test "returns file content when cached" do
      # Setup: create a cached file
      test_path = @tmp_path <> "#{Mix.env()}_#{@test_id}"
      File.write!(test_path, @test_content)

      # Test
      result = Cache.get_cache(@test_id)

      # Assertions
      assert result == @test_content
    end

    test "returns :error when file not cached" do
      # Test
      result = Cache.get_cache(@test_id)

      # Assertions
      assert result == :error
    end

    test "handles binary content correctly" do
      # Setup: create a cached file with binary content
      binary_content = <<1, 2, 3, 4, 5>>
      test_path = @tmp_path <> "#{Mix.env()}_#{@test_id}"
      File.write!(test_path, binary_content)

      # Test
      result = Cache.get_cache(@test_id)

      # Assertions
      assert result == binary_content
    end
  end

  describe "remove_from_cache/1" do
    test "removes existing cached file" do
      # Setup: create a cached file
      test_path = @tmp_path <> "#{Mix.env()}_#{@test_id}"
      File.write!(test_path, @test_content)
      assert File.exists?(test_path)

      # Test
      result = Cache.remove_from_cache(@test_id)

      # Assertions
      assert result == :ok
      refute File.exists?(test_path)
    end

    test "returns :ok when file doesn't exist" do
      # Test
      result = Cache.remove_from_cache(@test_id)

      # Assertions
      assert result == :ok
    end

    test "only removes the specific file" do
      # Setup: create multiple cached files
      test_path1 = @tmp_path <> "#{Mix.env()}_#{@test_id}"
      test_path2 = @tmp_path <> "#{Mix.env()}_other_file"
      File.write!(test_path1, @test_content)
      File.write!(test_path2, "other content")

      # Test
      result = Cache.remove_from_cache(@test_id)

      # Assertions
      assert result == :ok
      refute File.exists?(test_path1)
      assert File.exists?(test_path2)
    end
  end

  describe "cleanup_old_files/1" do
    test "removes files older than specified age" do
      # Setup: create old and new files
      old_file = @tmp_path <> "#{Mix.env()}_old_file"
      new_file = @tmp_path <> "#{Mix.env()}_new_file"
      
      File.write!(old_file, "old content")
      File.write!(new_file, "new content")

      # Make old file appear old by setting its modification time to 2 hours ago
      two_hours_ago = :calendar.datetime_to_gregorian_seconds(:calendar.universal_time()) - 7200
      old_datetime = :calendar.gregorian_seconds_to_datetime(two_hours_ago)
      File.touch!(old_file, old_datetime)

      # Test - cleanup files older than 1 minute
      result = Cache.cleanup_old_files(1)

      # Assertions
      assert result == :ok
      refute File.exists?(old_file)
      assert File.exists?(new_file)
    end

    test "keeps files newer than specified age" do
      # Setup: create a recent file
      recent_file = @tmp_path <> "#{Mix.env()}_recent_file"
      File.write!(recent_file, "recent content")

      # Test - cleanup files older than 1 minute (this file should be kept)
      result = Cache.cleanup_old_files(1)

      # Assertions
      assert result == :ok
      assert File.exists?(recent_file)
    end

    test "handles non-existent cache directory gracefully" do
      # Remove cache directory
      File.rm_rf!(@tmp_path)

      # Test
      result = Cache.cleanup_old_files()

      # Assertions
      assert result == :ok
      # Directory should be created by the function
      assert File.exists?(@tmp_path)
    end

    test "handles empty cache directory" do
      # Ensure cache directory exists but is empty
      File.mkdir_p!(@tmp_path)

      # Test
      result = Cache.cleanup_old_files()

      # Assertions
      assert result == :ok
    end

    test "uses default age when not specified" do
      # Setup: create a very old file
      old_file = @tmp_path <> "#{Mix.env()}_very_old_file"
      File.write!(old_file, "very old content")
      
      # Make file very old (3 hours ago)
      three_hours_ago = :calendar.datetime_to_gregorian_seconds(:calendar.universal_time()) - 10800
      old_datetime = :calendar.gregorian_seconds_to_datetime(three_hours_ago)
      File.touch!(old_file, old_datetime)

      # Test - use default cleanup age (120 minutes)
      result = Cache.cleanup_old_files()

      # Assertions
      assert result == :ok
      refute File.exists?(old_file)
    end
  end

  describe "cache path generation" do
    test "generates unique paths for different environments" do
      # Test with current environment
      path1 = Cache.get_cache_path(@test_id)
      
      # Simulate different environment by checking the pattern
      assert String.contains?(path1, to_string(Mix.env()))
      assert String.ends_with?(path1, @test_id)
    end

    test "generates consistent paths for same ID" do
      # Test multiple calls return same path
      path1 = Cache.get_cache_path(@test_id)
      path2 = Cache.get_cache_path(@test_id)
      
      assert path1 == path2
    end

    test "generates different paths for different IDs" do
      # Test different IDs return different paths
      path1 = Cache.get_cache_path(@test_id)
      path2 = Cache.get_cache_path("different_id")
      
      assert path1 != path2
    end
  end

  describe "cache directory management" do
    test "cache operations work when directory doesn't exist initially" do
      # Remove cache directory
      File.rm_rf!(@tmp_path)
      refute File.exists?(@tmp_path)

      # Test that cached? works even without directory
      result = Cache.cached?(@test_id)
      assert result == false

      # Test that get_cache works even without directory
      result = Cache.get_cache(@test_id)
      assert result == :error
    end
  end

  describe "file content handling" do
    test "handles empty files correctly" do
      # Setup: create empty cached file
      test_path = @tmp_path <> "#{Mix.env()}_#{@test_id}"
      File.write!(test_path, "")

      # Test cached?
      assert Cache.cached?(@test_id) == true

      # Test get_cache
      result = Cache.get_cache(@test_id)
      assert result == ""
    end

    test "handles large content correctly" do
      # Setup: create file with large content
      large_content = String.duplicate("A", 10_000)
      test_path = @tmp_path <> "#{Mix.env()}_#{@test_id}"
      File.write!(test_path, large_content)

      # Test
      result = Cache.get_cache(@test_id)

      # Assertions
      assert result == large_content
      assert byte_size(result) == 10_000
    end

    test "handles unicode content correctly" do
      # Setup: create file with unicode content
      unicode_content = "Hello 世界 🌍 café naïve résumé"
      test_path = @tmp_path <> "#{Mix.env()}_#{@test_id}"
      File.write!(test_path, unicode_content)

      # Test
      result = Cache.get_cache(@test_id)

      # Assertions
      assert result == unicode_content
    end
  end
end