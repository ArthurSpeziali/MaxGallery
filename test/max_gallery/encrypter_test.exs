defmodule MaxGallery.EncrypterTest do
    use MaxGallery.DataCase
    alias MaxGallery.Encrypter

    setup do
        {:ok,
            msg: "Lorem ipsum dolor sit amet, consectetur adipiscing elit."
        }
    end


    test "Encrypt a message, then decrypt it", %{msg: msg} do
        assert {:ok, enc} = Encrypter.encrypt(msg, "key")
        assert {:ok, _dec} = Encrypter.decrypt(enc, "key")
    end

    test "Create an file, encrypt its contents, then decrypt it.", %{msg: msg} do
        path = "/tmp/max_gallery_test#{Enum.random(0..10_000//1)}"
        File.write(path, msg, [:write])

        assert {:ok, {iv, _cypher}} = Encrypter.file(:encrypt, path, path <> "_dec", "key")
        assert {:ok, ^msg} = Encrypter.file(:decrypt, path <> "_dec", iv, "key")
    end

end
