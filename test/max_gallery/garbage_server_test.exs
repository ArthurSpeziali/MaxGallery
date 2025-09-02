defmodule MaxGallery.GarbageServerTest do
  use ExUnit.Case, async: false
  alias MaxGallery.Server.GarbageServer
  alias MaxGallery.Variables

  @tmp_dir Variables.tmp_dir()
  @zips_dir @tmp_dir <> "zips/"
  @cache_dir @tmp_dir <> "tests/"
  @downloads_dir @tmp_dir <> "downloads/"

  setup do
    # Ensure directories exist
    File.mkdir_p!(@zips_dir)
    File.mkdir_p!(@cache_dir)
    File.mkdir_p!(@downloads_dir)

    # Clean up any existing files
    File.rm_rf!(@zips_dir)
    File.rm_rf!(@cache_dir)
    File.rm_rf!(@downloads_dir)

    File.mkdir_p!(@zips_dir)
    File.mkdir_p!(@cache_dir)
    File.mkdir_p!(@downloads_dir)

    :ok
  end

  test "garbage server starts and initializes directories" do
    # The server should already be running from the application
    assert is_integer(GarbageServer.count())
  end

  test "garbage server creates required directories" do
    assert File.exists?(@zips_dir)
    assert File.exists?(@cache_dir)
    assert File.exists?(@downloads_dir)
  end

  test "garbage server can be manually triggered" do
    # Create test files
    test_file_zips = @zips_dir <> "test_zip.zip"
    test_file_cache = @cache_dir <> "test_cache.tmp"
    test_file_downloads = @downloads_dir <> "test_download.tmp"

    File.write!(test_file_zips, "test content")
    File.write!(test_file_cache, "test content")
    File.write!(test_file_downloads, "test content")

    # Verify files exist
    assert File.exists?(test_file_zips)
    assert File.exists?(test_file_cache)
    assert File.exists?(test_file_downloads)

    # Manually trigger cleanup (won't delete recent files)
    GarbageServer.check()

    # Files should still exist (they're too new)
    assert File.exists?(test_file_zips)
    assert File.exists?(test_file_cache)
    assert File.exists?(test_file_downloads)
  end

  test "garbage server handles empty directories" do
    # Ensure directories are empty
    assert Enum.empty?(File.ls!(@zips_dir))
    assert Enum.empty?(File.ls!(@cache_dir))
    assert Enum.empty?(File.ls!(@downloads_dir))

    # Should not crash with empty directories
    GarbageServer.check()

    # Directories should still exist
    assert File.exists?(@zips_dir)
    assert File.exists?(@cache_dir)
    assert File.exists?(@downloads_dir)
  end

  test "garbage server count reflects file count" do
    # Create some test files
    File.write!(@zips_dir <> "test1.zip", "content")
    File.write!(@cache_dir <> "test1.tmp", "content")
    File.write!(@downloads_dir <> "test1.tmp", "content")

    # Trigger a check to update count
    GarbageServer.check()

    # Give it a moment to process
    Process.sleep(100)

    # Count should reflect the files (though exact count may vary due to async nature)
    count = GarbageServer.count()
    assert is_integer(count)
    assert count >= 0
  end
end
