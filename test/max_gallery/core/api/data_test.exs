defmodule MaxGallery.Core.Data.ApiTest do
    use MaxGallery.DataCase
    alias MaxGallery.Core.Data.Api
    alias MaxGallery.Encrypter


    test "Put 10 cyphers, and get all" do

        for item <- 1..10//1 do
            assert {:ok, _cyphers} = Api.insert(%{name: "Teste#{item}", blob: <<0>>})
        end

        assert {:ok, cyphers} = Api.all()
        assert 10 = Enum.count(cyphers)
    end

    test "Encrypt a message, then decrypt it" do
        assert {:ok, enc} = Encrypter.encrypt("Hello", "key")
        assert {:ok, _dec} = Encrypter.decrypt(enc, "key")
    end


end
