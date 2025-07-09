defmodule MaxGallery.Validate do
    def int(str) do
        if is_binary(str) do
            String.to_integer(str)
        else
            str
        end
    end



end
