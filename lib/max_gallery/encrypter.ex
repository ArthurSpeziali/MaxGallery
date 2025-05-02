defmodule MaxGallery.Encrypter do

    def file(:encrypt, path, key) do
        with {:ok, content} <- File.read(path),
             {:ok, {iv, cypher}} <- encrypt(content, key) do

            {:ok, {iv, cypher}}
        else
            error -> error
        end
    end

    def file(:decrypt, {iv, cypher}, path, key) do
        with {:ok, data} <- {iv, cypher} |> decrypt(key),
             :ok <- File.write(path, data, [:write]) do

            {:ok, data}
        else
            error -> error
        end
    end


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
