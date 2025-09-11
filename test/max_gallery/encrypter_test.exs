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
    {iv, cypher} = Encrypter.encrypt(msg, "key")
    assert ^msg = Encrypter.decrypt(cypher, iv, "key")
  end

  test "Create an file, encrypt its contents, then decrypt it.", %{msg: msg} do
    path = create_file(msg)
    
    # Read file content and encrypt it
    content = File.read!(path)
    {iv, cypher} = Encrypter.encrypt(content, "key")
    
    # Decrypt and verify
    decrypted = Encrypter.decrypt(cypher, iv, "key")
    assert ^msg = decrypted

    TestHelpers.cleanup_temp_files()
  end
end
