defmodule MaxGallery.Phantom do

    defp validate_bin(binary) do
        if String.valid?(binary) do
            binary
        else
            Base.encode64(binary) <> get_ext(binary)
        end 
    end

    defp get_ext(binary) do
        charlist = :binary.bin_to_list(binary)

        index = Enum.reverse(charlist)
                |> Enum.find_index(fn item ->
                    item == ?.
                end)

        if index do
            point = Enum.count(charlist) - index - 1

            Enum.slice(charlist, point..-1//1)
            |> List.to_string()
        else
            ""
        end
    end

    def encode_bin(datas) do
        Enum.map(datas, fn item -> 
            Map.update!(item, :name, &validate_bin/1)
            |> Map.update!(:blob, &validate_bin/1)
        end)
    end

end
