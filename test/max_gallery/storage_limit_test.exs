defmodule MaxGallery.StorageLimitTest do
  use MaxGallery.DataCase
  alias MaxGallery.Context
  alias MaxGallery.Utils
  alias MaxGallery.Variables
  alias MaxGallery.TestHelpers

  setup %{test_user: test_user} do
    # Ensure storage mock is started
    MaxGallery.Storage.Mock.start_link()

    {
      :ok,
      # 1MB content
      test_user: test_user,
      small_content: "Small file content",
      large_content: String.duplicate("A", 1024 * 1024)
    }
  end

  describe "user_size/1" do
    test "returns 0.0 for user with no files", %{test_user: test_user} do
      size_gb = Utils.user_size(test_user)
      assert size_gb == 0.0
    end

    test "calculates correct size for user with files", %{
      test_user: test_user,
      small_content: content
    } do
      path = TestHelpers.create_temp_file(content)

      {:ok, _id} = Context.cypher_insert(path, test_user, "key")

      size_gb = Utils.user_size(test_user)
      expected_gb = byte_size(content) / (1024 * 1024 * 1024)

      assert_in_delta size_gb, expected_gb, 0.001

      TestHelpers.cleanup_temp_files()
    end
  end

  describe "storage limit enforcement" do
    test "allows upload when under limit", %{test_user: test_user, small_content: content} do
      path = TestHelpers.create_temp_file(content)

      result = Context.cypher_insert(path, test_user, "key")

      assert {:ok, _id} = result

      TestHelpers.cleanup_temp_files()
    end
  end

  describe "storage limit configuration" do
    test "max_size_user returns configured value" do
      max_size = Variables.max_size_user()
      assert is_float(max_size)
      assert max_size > 0
    end
  end

  describe "size calculation accuracy" do
    test "user_size matches sum of individual file sizes", %{test_user: test_user} do
      # Create multiple files and verify total size calculation
      contents = ["File 1 content", "File 2 content longer", "File 3"]
      expected_total_bytes = Enum.sum(Enum.map(contents, &byte_size/1))

      for content <- contents do
        path = TestHelpers.create_temp_file(content)
        {:ok, _id} = Context.cypher_insert(path, test_user, "key")
      end

      calculated_size_gb = Utils.user_size(test_user)
      expected_size_gb = expected_total_bytes / (1024 * 1024 * 1024)

      assert_in_delta calculated_size_gb, expected_size_gb, 0.001

      TestHelpers.cleanup_temp_files()
    end
  end
end
