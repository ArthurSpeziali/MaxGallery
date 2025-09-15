defmodule MaxGallery.CoreTest do
  use MaxGallery.DataCase, async: false
  alias MaxGallery.Core.{Cypher, Group, User}
  alias MaxGallery.Core.Cypher.Api, as: CypherApi
  alias MaxGallery.Core.Group.Api, as: GroupApi
  alias MaxGallery.Core.User.Api, as: UserApi
  
  setup %{test_user: user} do
    # Clean up all user data after each test
    on_exit(fn ->
      try do
        # Clean up groups and cyphers for this user
        GroupApi.delete_all(user)
        CypherApi.delete_all(user)
      rescue
        _ -> :ok  # Ignore errors during cleanup
      end
    end)
    
    :ok
  end

  describe "Cypher schema" do
    test "has correct fields" do
      expected_fields = [
        :id, :file, :name, :name_iv, :blob_iv, :ext, :msg, :msg_iv, 
        :length, :user_id, :group_id, :inserted_at, :updated_at
      ]
      
      actual_fields = Cypher.fields() ++ [:id, :inserted_at, :updated_at]
      
      for field <- expected_fields do
        assert field in actual_fields, "Field #{field} missing from Cypher schema"
      end
    end

    test "changeset accepts valid parameters" do
      params = %{
        file: 1,
        name: <<1, 2, 3>>,
        name_iv: <<4, 5, 6>>,
        blob_iv: <<7, 8, 9>>,
        ext: ".txt",
        group_id: 123,
        msg: "test_msg",
        msg_iv: "test_msg_iv",
        user_id: Ecto.UUID.generate()
      }
      
      changeset = Cypher.changeset(%Cypher{}, params)
      assert changeset.valid?
    end

    test "changeset has default values" do
      changeset = Cypher.changeset(%Cypher{}, %{})
      
      # Check default values are applied
      assert Ecto.Changeset.get_field(changeset, :file) == 0
      assert Ecto.Changeset.get_field(changeset, :ext) == ".txt"
      assert Ecto.Changeset.get_field(changeset, :length) == 0
    end
  end

  describe "Group schema" do
    test "has correct fields" do
      expected_fields = [
        :id, :name_iv, :name, :msg_iv, :msg, :user_id, :group_id, 
        :inserted_at, :updated_at
      ]
      
      actual_fields = Group.fields() ++ [:id, :inserted_at, :updated_at]
      
      for field <- expected_fields do
        assert field in actual_fields, "Field #{field} missing from Group schema"
      end
    end

    test "changeset accepts valid parameters" do
      params = %{
        name: <<1, 2, 3>>,
        name_iv: <<4, 5, 6>>,
        group_id: 456,
        msg: <<7, 8, 9>>,
        msg_iv: <<10, 11, 12>>,
        user_id: Ecto.UUID.generate()
      }
      
      changeset = Group.changeset(%Group{}, params)
      assert changeset.valid?
    end

    test "supports self-referential relationship" do
      # This tests that a group can have a parent group
      params = %{
        name: <<1, 2, 3>>,
        name_iv: <<4, 5, 6>>,
        group_id: nil,  # Root group
        msg: <<7, 8, 9>>,
        msg_iv: <<10, 11, 12>>,
        user_id: Ecto.UUID.generate()
      }
      
      changeset = Group.changeset(%Group{}, params)
      assert changeset.valid?
    end
  end

  describe "User schema" do
    test "has correct fields" do
      expected_fields = [
        :id, :name, :passhash, :email, :last_file, :inserted_at, :updated_at
      ]
      
      actual_fields = User.fields() ++ [:id, :inserted_at, :updated_at]
      
      for field <- expected_fields do
        assert field in actual_fields, "Field #{field} missing from User schema"
      end
    end

    test "changeset accepts valid parameters" do
      params = %{
        name: "Test User",
        passhash: <<1, 2, 3, 4, 5>>,
        email: "test@example.com",
        last_file: 5
      }
      
      changeset = User.changeset(%User{}, params)
      assert changeset.valid?
    end

    test "changeset has default values" do
      changeset = User.changeset(%User{}, %{})
      
      # Check default value for last_file
      assert Ecto.Changeset.get_field(changeset, :last_file) == 1
    end
  end

  describe "CypherApi" do
    test "insert creates new cypher record", %{test_user: user} do
      params = %{
        user_id: user,
        name: <<1, 2, 3>>,
        name_iv: <<4, 5, 6>>,
        blob_iv: <<7, 8, 9>>,
        ext: ".txt",
        msg: "test_msg",
        msg_iv: "test_msg_iv",
        length: 100
      }
      
      {:ok, cypher} = CypherApi.insert(user, params)
      
      assert cypher.id
      assert cypher.user_id == user
      assert cypher.name == <<1, 2, 3>>
      assert cypher.ext == ".txt"
      assert cypher.length == 100
    end

    test "get retrieves cypher by id", %{test_user: user} do
      params = %{
        user_id: user,
        name: <<1, 2, 3>>,
        name_iv: <<4, 5, 6>>,
        blob_iv: <<7, 8, 9>>,
        ext: ".jpg",
        msg: "test_msg",
        msg_iv: "test_msg_iv",
        length: 200
      }
      
      {:ok, created} = CypherApi.insert(user, params)
      {:ok, retrieved} = CypherApi.get(user, created.id)
      
      assert retrieved.id == created.id
      assert retrieved.name == created.name
      assert retrieved.ext == ".jpg"
      assert retrieved.length == 200
    end

    test "update modifies cypher record", %{test_user: user} do
      params = %{
        user_id: user,
        name: <<1, 2, 3>>,
        name_iv: <<4, 5, 6>>,
        blob_iv: <<7, 8, 9>>,
        ext: ".txt",
        msg: "test_msg",
        msg_iv: "test_msg_iv",
        length: 100
      }
      
      {:ok, cypher} = CypherApi.insert(user, params)
      
      update_params = %{
        ext: ".pdf",
        length: 150
      }
      
      {:ok, updated} = CypherApi.update(user, cypher.id, update_params)
      
      assert updated.id == cypher.id
      assert updated.name == <<1, 2, 3>>  # Unchanged
      assert updated.ext == ".pdf"
      assert updated.length == 150  # Updated
    end

    test "delete removes cypher record", %{test_user: user} do
      params = %{
        user_id: user,
        name: <<1, 2, 3>>,
        name_iv: <<4, 5, 6>>,
        blob_iv: <<7, 8, 9>>,
        ext: ".txt",
        msg: "test_msg",
        msg_iv: "test_msg_iv",
        length: 100
      }
      
      {:ok, cypher} = CypherApi.insert(user, params)
      {:ok, deleted} = CypherApi.delete(user, cypher.id)
      
      assert deleted.id == cypher.id
      
      # Should not be found after deletion
      assert {:error, "not found"} = CypherApi.get(user, cypher.id)
    end

    test "all_group returns cyphers in specific group", %{test_user: user} do
      # Create group first
      group_params = %{
        user_id: user,
        name: <<1, 2, 3>>,
        name_iv: <<4, 5, 6>>,
        msg: <<7, 8, 9>>,
        msg_iv: <<10, 11, 12>>
      }
      {:ok, group} = GroupApi.insert(user, group_params)
      
      # Create cyphers in group
      cypher_params1 = %{
        user_id: user,
        name: <<1, 2, 3>>,
        name_iv: <<4, 5, 6>>,
        blob_iv: <<7, 8, 9>>,
        ext: ".txt",
        msg: "test_msg",
        msg_iv: "test_msg_iv",
        group_id: group.id
      }
      
      cypher_params2 = %{
        user_id: user,
        name: <<10, 11, 12>>,
        name_iv: <<13, 14, 15>>,
        blob_iv: <<16, 17, 18>>,
        ext: ".jpg",
        msg: "test_msg2",
        msg_iv: "test_msg_iv2",
        group_id: group.id
      }
      
      {:ok, cypher1} = CypherApi.insert(user, cypher_params1)
      {:ok, cypher2} = CypherApi.insert(user, cypher_params2)
      
      # Create cypher in different group (should not be returned)
      cypher_params3 = %{
        user_id: user,
        name: <<20, 21, 22>>,
        name_iv: <<23, 24, 25>>,
        blob_iv: <<26, 27, 28>>,
        ext: ".pdf",
        msg: "test_msg3",
        msg_iv: "test_msg_iv3",
        group_id: nil  # Root group
      }
      {:ok, _cypher3} = CypherApi.insert(user, cypher_params3)
      
      {:ok, group_cyphers} = CypherApi.all_group(user, group.id)
      
      assert length(group_cyphers) == 2
      cypher_ids = Enum.map(group_cyphers, & &1.id)
      assert cypher1.id in cypher_ids
      assert cypher2.id in cypher_ids
    end

    test "first_one returns first cypher for user", %{test_user: user} do
      # Should return error when no cyphers exist
      assert {:error, "not found"} = CypherApi.first_one(user)
      
      # Create cypher
      params = %{
        user_id: user,
        name: <<1, 2, 3>>,
        name_iv: <<4, 5, 6>>,
        blob_iv: <<7, 8, 9>>,
        ext: ".txt",
        msg: "test_msg",
        msg_iv: "test_msg_iv"
      }
      
      {:ok, cypher} = CypherApi.insert(user, params)
      
      # Should return the cypher
      {:ok, first} = CypherApi.first_one(user)
      assert first.id == cypher.id
    end

    test "get_length returns cypher length", %{test_user: user} do
      params = %{
        user_id: user,
        name: <<1, 2, 3>>,
        name_iv: <<4, 5, 6>>,
        blob_iv: <<7, 8, 9>>,
        ext: ".txt",
        msg: "test_msg",
        msg_iv: "test_msg_iv",
        length: 12345
      }
      
      {:ok, cypher} = CypherApi.insert(user, params)
      {:ok, length} = CypherApi.get_length(user, cypher.id)
      
      assert length == 12345
    end

    test "get_timestamps returns cypher timestamps", %{test_user: user} do
      params = %{
        user_id: user,
        name: <<1, 2, 3>>,
        name_iv: <<4, 5, 6>>,
        blob_iv: <<7, 8, 9>>,
        ext: ".txt",
        msg: "test_msg",
        msg_iv: "test_msg_iv"
      }
      
      {:ok, cypher} = CypherApi.insert(user, params)
      {:ok, timestamps} = CypherApi.get_timestamps(user, cypher.id)
      
      assert Map.has_key?(timestamps, :inserted_at)
      assert Map.has_key?(timestamps, :updated_at)
      assert %NaiveDateTime{} = timestamps.inserted_at
      assert %NaiveDateTime{} = timestamps.updated_at
    end

    test "all_size returns all cypher sizes for user", %{test_user: user} do
      # Create cyphers with different sizes
      params1 = %{
        user_id: user,
        name: <<1, 2, 3>>,
        name_iv: <<4, 5, 6>>,
        blob_iv: <<7, 8, 9>>,
        ext: ".txt",
        msg: "test_msg",
        msg_iv: "test_msg_iv",
        length: 100
      }
      
      params2 = %{
        user_id: user,
        name: <<10, 11, 12>>,
        name_iv: <<13, 14, 15>>,
        blob_iv: <<16, 17, 18>>,
        ext: ".jpg",
        msg: "test_msg2",
        msg_iv: "test_msg_iv2",
        length: 200
      }
      
      {:ok, _cypher1} = CypherApi.insert(user, params1)
      {:ok, _cypher2} = CypherApi.insert(user, params2)
      
      {:ok, sizes} = CypherApi.all_size(user)
      
      assert 100 in sizes
      assert 200 in sizes
      assert length(sizes) >= 2
    end

    test "delete_all removes all cyphers for user", %{test_user: user} do
      # Create multiple cyphers
      for i <- 1..3 do
        params = %{
          user_id: user,
          name: <<i>>,
          name_iv: <<i + 10>>,
          blob_iv: <<i + 20>>,
          ext: ".txt",
          msg: "test_msg_#{i}",
          msg_iv: "test_msg_iv_#{i}"
        }
        {:ok, _cypher} = CypherApi.insert(user, params)
      end
      
      # Verify cyphers exist
      {:ok, sizes_before} = CypherApi.all_size(user)
      assert length(sizes_before) >= 3
      
      # Delete all
      {count, nil} = CypherApi.delete_all(user)
      assert count >= 3
      
      # Verify all are gone
      {:ok, sizes_after} = CypherApi.all_size(user)
      assert sizes_after == []
    end
  end

  describe "GroupApi" do
    test "insert creates new group record", %{test_user: user} do
      params = %{
        user_id: user,
        name: <<1, 2, 3>>,
        name_iv: <<4, 5, 6>>,
        msg: <<7, 8, 9>>,
        msg_iv: <<10, 11, 12>>
      }
      
      {:ok, group} = GroupApi.insert(user, params)
      
      assert group.id
      assert group.user_id == user
      assert group.name == <<1, 2, 3>>
      assert group.name_iv == <<4, 5, 6>>
    end

    test "get retrieves group by id", %{test_user: user} do
      params = %{
        user_id: user,
        name: <<1, 2, 3>>,
        name_iv: <<4, 5, 6>>,
        msg: <<7, 8, 9>>,
        msg_iv: <<10, 11, 12>>
      }
      
      {:ok, created} = GroupApi.insert(user, params)
      {:ok, retrieved} = GroupApi.get(user, created.id)
      
      assert retrieved.id == created.id
      assert retrieved.name == created.name
      assert retrieved.name_iv == created.name_iv
    end

    test "update modifies group record", %{test_user: user} do
      params = %{
        user_id: user,
        name: <<1, 2, 3>>,
        name_iv: <<4, 5, 6>>,
        msg: <<7, 8, 9>>,
        msg_iv: <<10, 11, 12>>
      }
      
      {:ok, group} = GroupApi.insert(user, params)
      
      update_params = %{
        name: <<20, 21, 22>>,
        name_iv: <<23, 24, 25>>
      }
      
      {:ok, updated} = GroupApi.update(user, group.id, update_params)
      
      assert updated.id == group.id
      assert updated.name == <<20, 21, 22>>
      assert updated.name_iv == <<23, 24, 25>>
    end

    test "delete removes group record", %{test_user: user} do
      params = %{
        user_id: user,
        name: <<1, 2, 3>>,
        name_iv: <<4, 5, 6>>,
        msg: <<7, 8, 9>>,
        msg_iv: <<10, 11, 12>>
      }
      
      {:ok, group} = GroupApi.insert(user, params)
      {:ok, deleted} = GroupApi.delete(user, group.id)
      
      assert deleted.id == group.id
      
      # Should not be found after deletion
      assert {:error, "not found"} = GroupApi.get(user, group.id)
    end

    test "all_group returns groups in specific parent group", %{test_user: user} do
      # Create parent group
      parent_params = %{
        user_id: user,
        name: <<1, 2, 3>>,
        name_iv: <<4, 5, 6>>,
        msg: <<7, 8, 9>>,
        msg_iv: <<10, 11, 12>>
      }
      {:ok, parent} = GroupApi.insert(user, parent_params)
      
      # Create child groups
      child_params1 = %{
        user_id: user,
        name: <<11, 12, 13>>,
        name_iv: <<14, 15, 16>>,
        msg: <<17, 18, 19>>,
        msg_iv: <<20, 21, 22>>,
        group_id: parent.id
      }
      
      child_params2 = %{
        user_id: user,
        name: <<31, 32, 33>>,
        name_iv: <<34, 35, 36>>,
        msg: <<37, 38, 39>>,
        msg_iv: <<40, 41, 42>>,
        group_id: parent.id
      }
      
      {:ok, child1} = GroupApi.insert(user, child_params1)
      {:ok, child2} = GroupApi.insert(user, child_params2)
      
      # Create group in different parent (should not be returned)
      other_params = %{
        user_id: user,
        name: <<51, 52, 53>>,
        name_iv: <<54, 55, 56>>,
        msg: <<57, 58, 59>>,
        msg_iv: <<60, 61, 62>>,
        group_id: nil  # Root group
      }
      {:ok, _other} = GroupApi.insert(user, other_params)
      
      {:ok, child_groups} = GroupApi.all_group(user, parent.id)
      
      assert length(child_groups) == 2
      group_ids = Enum.map(child_groups, & &1.id)
      assert child1.id in group_ids
      assert child2.id in group_ids
    end

    test "get_timestamps returns group timestamps", %{test_user: user} do
      params = %{
        user_id: user,
        name: <<1, 2, 3>>,
        name_iv: <<4, 5, 6>>,
        msg: <<7, 8, 9>>,
        msg_iv: <<10, 11, 12>>
      }
      
      {:ok, group} = GroupApi.insert(user, params)
      {:ok, timestamps} = GroupApi.get_timestamps(user, group.id)
      
      assert Map.has_key?(timestamps, :inserted_at)
      assert Map.has_key?(timestamps, :updated_at)
      assert %NaiveDateTime{} = timestamps.inserted_at
      assert %NaiveDateTime{} = timestamps.updated_at
    end

    test "delete_all removes all groups for user", %{test_user: user} do
      # Create multiple groups
      for i <- 1..3 do
        params = %{
          user_id: user,
          name: <<i>>,
          name_iv: <<i + 10>>,
          msg: <<i + 20>>,
          msg_iv: <<i + 30>>
        }
        {:ok, _group} = GroupApi.insert(user, params)
      end
      
      # Verify groups exist
      {:ok, groups_before} = GroupApi.all_group(user, nil)
      assert length(groups_before) >= 3
      
      # Delete all
      {count, nil} = GroupApi.delete_all(user)
      assert count >= 3
      
      # Verify all are gone
      {:ok, groups_after} = GroupApi.all_group(user, nil)
      assert groups_after == []
    end
  end

  describe "UserApi" do
    test "insert creates new user record" do
      params = %{
        name: "Test User",
        email: "test_user_#{System.unique_integer([:positive])}@example.com",
        passhash: <<1, 2, 3, 4, 5>>
      }
      
      {:ok, user} = UserApi.insert(params)
      
      assert user.id
      assert user.name == "Test User"
      assert user.email == params.email
      assert user.passhash == <<1, 2, 3, 4, 5>>
      assert user.last_file == 1  # Default value
    end

    test "get retrieves user by id" do
      params = %{
        name: "Get Test User",
        email: "get_test_#{System.unique_integer([:positive])}@example.com",
        passhash: <<6, 7, 8, 9, 10>>
      }
      
      {:ok, created} = UserApi.insert(params)
      {:ok, retrieved} = UserApi.get(created.id)
      
      assert retrieved.id == created.id
      assert retrieved.name == "Get Test User"
      assert retrieved.email == params.email
    end

    test "get_email retrieves user by email" do
      email = "email_test_#{System.unique_integer([:positive])}@example.com"
      params = %{
        name: "Email Test User",
        email: email,
        passhash: <<11, 12, 13, 14, 15>>
      }
      
      {:ok, created} = UserApi.insert(params)
      {:ok, retrieved} = UserApi.get_email(email)
      
      assert retrieved.id == created.id
      assert retrieved.email == email
    end

    test "update modifies user record" do
      params = %{
        name: "Update Test User",
        email: "update_test_#{System.unique_integer([:positive])}@example.com",
        passhash: <<16, 17, 18, 19, 20>>
      }
      
      {:ok, user} = UserApi.insert(params)
      
      update_params = %{
        name: "Updated Name",
        last_file: 5
      }
      
      {:ok, updated} = UserApi.update(user.id, update_params)
      
      assert updated.id == user.id
      assert updated.name == "Updated Name"
      assert updated.last_file == 5
      assert updated.email == params.email  # Unchanged
    end

    test "delete removes user record" do
      params = %{
        name: "Delete Test User",
        email: "delete_test_#{System.unique_integer([:positive])}@example.com",
        passhash: <<21, 22, 23, 24, 25>>
      }
      
      {:ok, user} = UserApi.insert(params)
      {:ok, deleted} = UserApi.delete(user.id)
      
      assert deleted.id == user.id
      
      # Should not be found after deletion
      assert {:error, "not found"} = UserApi.get(user.id)
    end

    test "exists checks if user exists" do
      params = %{
        name: "Exists Test User",
        email: "exists_test_#{System.unique_integer([:positive])}@example.com",
        passhash: <<26, 27, 28, 29, 30>>
      }
      
      {:ok, user} = UserApi.insert(params)
      
      # Should exist
      {:ok, _existing} = UserApi.exists(user.id)
      
      # Delete and check again
      {:ok, _deleted} = UserApi.delete(user.id)
      assert {:error, "not found"} = UserApi.exists(user.id)
    end

    test "handles duplicate email constraint" do
      email = "duplicate_#{System.unique_integer([:positive])}@example.com"
      
      params1 = %{
        name: "First User",
        email: email,
        passhash: <<1, 2, 3>>
      }
      
      params2 = %{
        name: "Second User",
        email: email,
        passhash: <<4, 5, 6>>
      }
      
      # First insert should succeed
      {:ok, _user1} = UserApi.insert(params1)
      
      # Second insert with same email should fail
      assert_raise Ecto.ConstraintError, fn ->
        UserApi.insert(params2)
      end
    end
  end

  describe "Cross-module relationships" do
    test "user has many cyphers relationship", %{test_user: user} do
      # Create cyphers for user
      for i <- 1..3 do
        params = %{
          user_id: user,
          name: <<i>>,
          name_iv: <<i + 10>>,
          blob_iv: <<i + 20>>,
          ext: ".txt",
          msg: "test_msg_#{i}",
          msg_iv: "test_msg_iv_#{i}"
        }
        {:ok, _cypher} = CypherApi.insert(user, params)
      end
      
      # Verify user has cyphers
      {:ok, sizes} = CypherApi.all_size(user)
      assert length(sizes) >= 3
    end

    test "group has many cyphers relationship", %{test_user: user} do
      # Create group
      group_params = %{
        user_id: user,
        name: <<1, 2, 3>>,
        name_iv: <<4, 5, 6>>,
        msg: <<7, 8, 9>>,
        msg_iv: <<10, 11, 12>>
      }
      {:ok, group} = GroupApi.insert(user, group_params)
      
      # Create cyphers in group
      for i <- 1..2 do
        cypher_params = %{
          user_id: user,
          name: <<i>>,
          name_iv: <<i + 10>>,
          blob_iv: <<i + 20>>,
          ext: ".txt",
          msg: "test_msg_#{i}",
          msg_iv: "test_msg_iv_#{i}",
          group_id: group.id
        }
        {:ok, _cypher} = CypherApi.insert(user, cypher_params)
      end
      
      # Verify group has cyphers
      {:ok, group_cyphers} = CypherApi.all_group(user, group.id)
      assert length(group_cyphers) == 2
    end

    test "group self-referential relationship", %{test_user: user} do
      # Create parent group
      parent_params = %{
        user_id: user,
        name: <<1, 2, 3>>,
        name_iv: <<4, 5, 6>>,
        msg: <<7, 8, 9>>,
        msg_iv: <<10, 11, 12>>
      }
      {:ok, parent} = GroupApi.insert(user, parent_params)
      
      # Create child group
      child_params = %{
        user_id: user,
        name: <<11, 12, 13>>,
        name_iv: <<14, 15, 16>>,
        msg: <<17, 18, 19>>,
        msg_iv: <<20, 21, 22>>,
        group_id: parent.id
      }
      {:ok, child} = GroupApi.insert(user, child_params)
      
      # Verify relationship
      {:ok, retrieved_child} = GroupApi.get(user, child.id)
      # The group_id field contains the internal ID, but we need to check the relationship exists
      # Since we're testing the API layer, we should check that the child has a parent reference
      assert retrieved_child.group_id != nil
      
      # Verify parent has child
      {:ok, children} = GroupApi.all_group(user, parent.id)
      assert length(children) == 1
      assert List.first(children).id == child.id
    end
  end
end