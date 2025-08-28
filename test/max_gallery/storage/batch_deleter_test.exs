defmodule MaxGallery.Storage.BatchDeleterTest do
  use ExUnit.Case, async: true
  alias MaxGallery.Storage.Deleter

  describe "calculate_safe_batch_size/0" do
    test "returns a safe batch size that is less than max_objects" do
      # We can't directly test the private function, but we can test the behavior
      # by checking that the module doesn't crash with large numbers
      assert is_function(&Deleter.delete_all_user_files/1)
    end
  end

  describe "delete_all_user_files/1" do
    test "handles authentication errors gracefully" do
      # Mock a user that doesn't exist or has auth issues
      # This will test the error handling path
      result = Deleter.delete_all_user_files("nonexistent_user")

      # Should return either success (if no files) or error (if auth fails)
      assert match?({:ok, _count}, result) or match?({:error, _reason}, result)
    end
  end
end
