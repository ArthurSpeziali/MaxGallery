defmodule MaxGallery.Phantom do
    alias MaxGallery.Encrypter

    defp validate_bin(binary) do
        if String.valid?(binary) do
            binary
        else
            Base.encode64(binary) <> get_ext(binary)
        end 
    end

    defp get_ext(binary) do
        ext = Path.extname(binary)

        if String.valid?(ext) do
            ext
        else
            ""
        end
    end

    def encode_bin(datas) when is_list(datas) do
        Enum.map(datas, fn item -> 
            Map.update!(item, :name, &validate_bin/1)
            |> Map.update!(:blob, &validate_bin/1)
        end)
    end
    def encode_bin(data) do
       encode_bin([data]) 
    end


    def valid?(querry, key) do
        {:ok, dec_data} = Encrypter.decrypt({querry.blob_iv, querry.blob}, key)
        IO.inspect(dec_data)

        String.valid?(dec_data)
    end

end
