defmodule MaxGallery.Phantom do
    alias MaxGallery.Encrypter

    defp validate_bin(binary) do
        if String.valid?(binary) do
            binary
        else
            Base.encode64(binary)
        end 
    end

    def encode_bin(datas) when is_list(datas) do
        Enum.map(datas, fn item -> 
            new_map = Map.update!(item, :name, &validate_bin/1)
            
            if new_map[:blob] do
                Map.update!(new_map, :blob, &validate_bin/1)
            else
                new_map
            end
        end)
    end
    def encode_bin(data) do
       encode_bin([data]) 
    end


    def get_text(), do: "encrypted_data"

    def valid?(%{msg_iv: msg_iv, msg: msg}, key) do
        {:ok, dec_cypher} = Encrypter.decrypt({msg_iv, msg}, key)

        dec_cypher == get_text()
    end

end
