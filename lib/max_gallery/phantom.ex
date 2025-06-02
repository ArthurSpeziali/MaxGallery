defmodule MaxGallery.Phantom do
    alias MaxGallery.Encrypter
    alias MaxGallery.Core.Data.Api


    def validate_bin(binary) do
        if String.printable?(binary) do
            binary
        else
            Base.encode64(binary)
        end 
    end

    def encode_bin(contents) when is_list(contents) do
        Enum.map(contents, fn item -> 
            new_content = Map.update!(item, :name, &validate_bin/1)
            
            if new_content[:blob] do
                Map.update!(new_content, :blob, &validate_bin/1)
            else
                new_content
            end
        end)
    end
    def encode_bin(content) do
       encode_bin([content]) 
    end


    def get_text(), do: "encrypted_data"

    def valid?(%{msg_iv: msg_iv, msg: msg}, key) do
        {:ok, dec_cypher} = Encrypter.decrypt({msg_iv, msg}, key)

        dec_cypher == get_text()
    end


    def insert_line?(key) do
        case Api.first() do
            {:error, nil} -> true
            {:ok, querry} -> valid?(querry, key)
        end
    end

end
