defmodule MaxGallery.EncrypterTest do
  use ExUnit.Case
  alias MaxGallery.Encrypter
  alias MaxGallery.TestHelpers

  setup do
    {:ok, msg: "Lorem ipsum dolor sit amet, consectetur adipiscing elit."}
  end

  defp create_file(msg) do
    TestHelpers.create_temp_file(msg)
  end

  test "Encrypt a message, then decrypt it", %{msg: msg} do
    assert {:ok, enc} = Encrypter.encrypt(msg, "key")
    assert {:ok, ^msg} = Encrypter.decrypt(enc, "key")
  end

  test "Create an file, encrypt its contents, then decrypt it.", %{msg: msg} do
    path = create_file(msg)

    assert {:ok, {iv, cypher}} = Encrypter.file(:encrypt, path, "key")
    assert {:ok, ^msg} = Encrypter.file(:decrypt, {iv, cypher}, path <> "_dec", "key")
    
    # Clean up the decrypted file
    File.rm(path <> "_dec")
    TestHelpers.cleanup_temp_files()
  end
end