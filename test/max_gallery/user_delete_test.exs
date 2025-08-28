defmodule MaxGallery.UserDeleteTest do
  use MaxGallery.DataCase
  alias MaxGallery.Context
  alias MaxGallery.TestHelpers

  setup do
    # Ensure storage mock is started
    MaxGallery.Storage.Mock.start_link()
    
    {:ok, msg: "Test file content for user deletion test"}
  end

  test "user_delete calls cleanup functions and deletes user" do
    # Create a test user
    test_user = TestHelpers.create_real_test_user()

    # Create some groups for the user (groups are easier to create than files)
    assert {:ok, _group_id1} = Context.group_insert("Test Group 1", test_user, "key")
    assert {:ok, _group_id2} = Context.group_insert("Test Group 2", test_user, "key")

    # Verify groups exist before deletion
    assert {:ok, groups_before} = Context.decrypt_all(test_user, "key", only: :groups)
    assert length(groups_before) >= 2

    # Delete the user (this should now delete all their data)
    assert :ok = Context.user_delete(test_user)

    # Verify user no longer exists
    assert {:error, _reason} = Context.user_get(test_user)
  end

  test "user_delete handles users with no data gracefully" do
    # Create a test user with no data
    test_user = TestHelpers.create_real_test_user()

    # Delete the user (should work even with no data)
    assert :ok = Context.user_delete(test_user)

    # Verify user no longer exists
    assert {:error, _reason} = Context.user_get(test_user)
  end

  test "user_delete returns error for non-existent user" do
    # Try to delete a non-existent user using a valid UUID format
    fake_user_id = Ecto.UUID.generate()
    
    # Should return error
    assert :error = Context.user_delete(fake_user_id)
  end
end