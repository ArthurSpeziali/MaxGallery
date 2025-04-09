defmodule MaxGallery.Phantom do
    alias MaxGallery.Encrypter

    defp validate_bin(binary) do
        if String.valid?(binary) do
            binary
        else
            Base.encode64(binary) <> Path.extname(binary)
        end 
    end

    def encode_bin(datas) do
        Enum.map(datas, fn item -> 
            Map.update!(item, :name, &validate_bin/1)
            |> Map.update!(:blob, &validate_bin/1)
        end)
    end


    def valid?(querry, key) do
        {:ok, dec_data} = Encrypter.decrypt({querry.name_iv, querry.name}, key)

        String.valid?(dec_data)
    end

end
