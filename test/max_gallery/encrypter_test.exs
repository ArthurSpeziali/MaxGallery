defmodule MaxGallery.EncrypterTest do
    use ExUnit.Case
    alias MaxGallery.Encrypter

    setup do
        {:ok,
            msg: "Lorem ipsum dolor sit amet, consectetur adipiscing elit."
        }
    end

    defp create_file(msg) do
        path = "/tmp/max_gallery/tests/test#{Enum.random(0..10_000//1)}"
        File.mkdir_p("/tmp/max_gallery/tests")
        File.write(path, msg, [:write])
        path
    end


    test "Encrypt a message, then decrypt it", %{msg: msg} do
        assert {:ok, enc} = Encrypter.encrypt(msg, "key")
        assert {:ok, _dec} = Encrypter.decrypt(enc, "key")
    end

    test "Create an file, encrypt its contents, then decrypt it.", %{msg: msg} do
        path = create_file(msg)

        assert {:ok, {iv, cypher}} = Encrypter.file(:encrypt, path, "key")
        assert {:ok, ^msg} = Encrypter.file(:decrypt, {iv, cypher}, path <> "_dec", "key")
    end

end
