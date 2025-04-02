defmodule MaxGallery.Encrypter do

    def file(path, key) do
        with {:ok, content} <- File.read(path),
             {:ok, enc} <- encrypt(content, key) do

            {:ok, enc}
        else
            error -> error
        end
    end


    def encrypt(data, _key) when not is_binary(data), do: {:error, "data is not binary"}
    def encrypt(_data, key) when not is_binary(key), do: {:error, "key is not binary"}

    def encrypt(data, key) do
        iv = :crypto.strong_rand_bytes(16)  
        hash_key = hash(key)

        cypher = :crypto.crypto_one_time(:aes_256_ctr, hash_key, iv, data, true)
        {:ok, {iv, cypher}}
    end


    def decrypt({iv, cypher}, key) do
        hash_key = hash(key)

        {:ok,
            :crypto.crypto_one_time(:aes_256_ctr, hash_key, iv, cypher, false)
        }
    end


    def hash(key) do
        :crypto.hash(:sha256, key)      
    end

end
