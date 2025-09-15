defmodule MaxGallery.SecurityTest do
  use MaxGallery.DataCase
  alias MaxGallery.Core.Cypher.Api, as: CypherApi
  alias MaxGallery.Core.Group.Api, as: GroupApi
  alias MaxGallery.Core.User.Api, as: UserApi

  describe "group_id security validation" do
    setup do
      # Create two users
      {:ok, user1} = UserApi.insert(%{
        name: "User 1",
        email: "user1@test.com",
        passhash: "hash1"
      })
      
      {:ok, user2} = UserApi.insert(%{
        name: "User 2", 
        email: "user2@test.com",
        passhash: "hash2"
      })

      # Create a group for user1
      {:ok, group1} = GroupApi.insert(user1.id, %{
        user_id: user1.id,
        name: "encrypted_name",
        name_iv: "iv",
        msg: "encrypted_msg",
        msg_iv: "msg_iv"
      })

      %{user1: user1.id, user2: user2.id, group1: group1}
    end

    test "user cannot insert cypher with group_id from another user", %{user2: user2, group1: group1} do
      # Try to insert a cypher for user2 using user1's group
      assert_raise Postgrex.Error, ~r/Cypher can only reference groups from the same user/, fn ->
        CypherApi.insert(user2, %{
          user_id: user2,
          name: "test_file",
          name_iv: "iv",
          blob_iv: "blob_iv",
          ext: ".txt",
          msg: "msg",
          msg_iv: "msg_iv",
          length: 100,
          group_id: group1.id  # This should fail - using user1's group public ID
        })
      end
    end

    test "user cannot update cypher to move it to another user's group", %{user2: user2, group1: group1} do
      # Create a cypher for user2
      {:ok, cypher2} = CypherApi.insert(user2, %{
        user_id: user2,
        name: "test_file",
        name_iv: "iv", 
        blob_iv: "blob_iv",
        ext: ".txt",
        msg: "msg",
        msg_iv: "msg_iv",
        length: 100
      })

      # Try to move it to user1's group
      assert_raise Postgrex.Error, ~r/Cypher can only reference groups from the same user/, fn ->
        CypherApi.update(user2, cypher2.id, %{
          group_id: group1.id  # This should fail
        })
      end
    end

    test "user cannot create subgroup under another user's group", %{user2: user2, group1: group1} do
      # Try to create a subgroup for user2 under user1's group
      assert_raise Postgrex.Error, ~r/Group can only reference parent groups from the same user/, fn ->
        GroupApi.insert(user2, %{
          user_id: user2,
          name: "subgroup",
          name_iv: "iv",
          msg: "msg", 
          msg_iv: "msg_iv",
          group_id: group1.id  # This should fail
        })
      end
    end

    test "user cannot list contents of another user's group", %{user2: user2, group1: group1} do
      # Try to list contents of user1's group as user2
      # This should return empty list since user2 can't see user1's groups
      {:ok, result} = CypherApi.all_group(user2, group1.id)
      
      assert result == []
    end

    test "user can perform valid operations on their own groups", %{user1: user1, group1: group1} do
      # User1 should be able to insert cypher in their own group
      result = CypherApi.insert(user1, %{
        user_id: user1,
        name: "valid_file",
        name_iv: "iv",
        blob_iv: "blob_iv", 
        ext: ".txt",
        msg: "msg",
        msg_iv: "msg_iv",
        length: 100,
        group_id: group1.id
      })

      assert {:ok, _cypher} = result
    end

    test "user can create subgroup under their own group", %{user1: user1, group1: group1} do
      # User1 should be able to create subgroup under their own group
      result = GroupApi.insert(user1, %{
        user_id: user1,
        name: "valid_subgroup",
        name_iv: "iv",
        msg: "msg",
        msg_iv: "msg_iv", 
        group_id: group1.id
      })

      assert {:ok, _subgroup} = result
    end
  end
end
