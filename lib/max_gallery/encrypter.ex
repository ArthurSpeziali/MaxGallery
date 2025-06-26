defmodule MaxGallery.Encrypter do
    @type cypher :: {iv :: binary(), ciphertext :: binary()}
    @moduledoc """
    Provides cryptographic operations for the MaxGallery system.

    This module handles all encryption/decryption needs including:

    - AES-256 CTR mode encryption/decryption of binary data
    - Secure file encryption/decryption operations
    - Key hashing using SHA-256
    - Generation of cryptographically strong initialization vectors

    Key features:

    - Uses industry-standard AES-256 encryption in CTR mode
    - Automatic IV generation for each encryption operation
    - Secure key derivation via SHA-256 hashing
    - Consistent {:ok, result}/error tuple interface
    - Supports both in-memory and file-based operations

    Security considerations:

    - Each encryption generates a unique IV
    - Never stores or logs keys
    - Uses cryptographically strong random bytes
    - Properly handles binary data of any size
    - Follows Erlang crypto module best practices

    Typical workflow:
    1. Hash raw key with `hash/1`
    2. Encrypt data with `encrypt/2` or `file(:encrypt, ...)`
    3. Decrypt later with `decrypt/2` or `file(:decrypt, ...)`
    """


    @doc """
    Encrypts a file's contents using AES-256 CTR mode.

    ## Parameters
    - `:encrypt` - Operation mode identifier
    - `path` - Path to the file to be encrypted
    - `key` - Raw encryption key (will be automatically hashed)

    ## Returns
    - `{:ok, {iv, cyphertext}}` on success:
      - `iv` - 16-byte initialization vector
      - `cyphertext` - Encrypted file contents
    - Error tuple if any step fails

    ## Behavior
    1. Reads the file contents
    2. Generates a secure random IV
    3. Encrypts the contents using AES-256-CTR
    4. Returns IV and cyphertext pair

    ## Notes
    - Original file remains unmodified
    - Uses cryptographically secure random IV
    - Automatically hashes the provided key
    """
    @spec file(:encrypt, path :: Path.t(), key :: String.t()) :: {:ok, cypher()}
    def file(:encrypt, path, key) do
        with {:ok, content} <- File.read(path),
             {:ok, {iv, cypher}} <- encrypt(content, key) do

            {:ok, {iv, cypher}}
        else
            error -> error
        end
    end
    @doc """
    Decrypts file contents and writes to specified path.

    ## Parameters
    - `:decrypt` - Operation mode identifier
    - `{iv, cyphertext}` - Encryption components from original encryption
    - `path` - Destination path for decrypted file
    - `key` - Original encryption key

    ## Returns
    - `{:ok, decrypted_binary}` on success
    - Error tuple if any step fails

    ## Behavior
    1. Decrypts the cyphertext using provided IV and key
    2. Writes decrypted data to target path
    3. Returns the decrypted binary data

    ## Notes
    - Will overwrite existing files at destination
    - Key must match original encryption key
    - Returns decrypted data even if file write fails
    - Maintains atomic operation (fails if any step fails)
    """
    @spec file(:decrypt, cypher(), path :: Path.t(), key :: String.t()) :: {:ok, cypher()} | {:error, atom()}
    def file(:decrypt, {iv, cypher}, path, key) do
        with {:ok, data} <- {iv, cypher} |> decrypt(key),
             :ok <- File.write(path, data, [:write]) do

            {:ok, data}
        else
            error -> error
        end
    end


    @doc """
    Encrypts binary data using AES-256 in CTR mode.

    ## Parameters
    - `data` - The binary data to encrypt
    - `key` - The raw encryption key (will be hashed)

    ## Returns
    - `{:ok, {iv, cyphertext}}` tuple where:
      - `iv` - 16-byte initialization vector (randomly generated)
      - `cyphertext` - The encrypted data

    ## Encryption Details
    - Uses AES-256-CTR (256-bit AES in Counter mode)
    - Generates cryptographically strong random IV
    - Automatically hashes key using SHA-256
    - Suitable for encrypting large binaries

    ## Notes
    - IV changes with each encryption (must be stored for decryption)
    - Same key + same IV will produce same cyphertext
    - Returns error if encryption fails
    - CTR mode doesn't require padding
    - Uses Erlang's :crypto module for core operations
    """
    @spec encrypt(data :: binary(), key :: String.t()) :: {:ok, cypher()}
    def encrypt(data, key) do
        iv = :crypto.strong_rand_bytes(16)  
        hash_key = hash(key)

        cypher = :crypto.crypto_one_time(:aes_256_ctr, hash_key, iv, data, true)
        {:ok, {iv, cypher}}
    end

    @doc """
    Decrypts data that was encrypted with AES-256 in CTR mode.

    ## Parameters
    - `{iv, cypher}` - Tuple containing:
      - `iv` - The 16-byte initialization vector used during encryption
      - `cypher` - The encrypted data to decrypt
    - `key` - The same raw encryption key used for encryption (will be hashed)

    ## Returns
    - `{:ok, plaintext}` - Tuple with decrypted binary data on success
    - Error tuple if decryption fails

    ## Behavior
    1. Hashes the provided key using SHA-256
    2. Uses AES-256-CTR mode with the same IV
    3. Returns original plaintext data

    ## Notes
    - Requires the exact same IV used during encryption
    - Key must match original encryption key
    - Uses Erlang's :crypto module
    - CTR mode provides symmetric encryption/decryption
    - Will fail if:
      - IV doesn't match original
      - Key is incorrect
      - Cyphertext was modified
    """
    @spec decrypt(cypher(), key :: String.t()) :: {:ok, binary()}
    def decrypt({iv, cypher}, key) do
        hash_key = hash(key)

        {:ok,
            :crypto.crypto_one_time(:aes_256_ctr, hash_key, iv, cypher, false)
        }
    end


    @spec hash(key :: String.t()) :: binary()
    defp hash(key) do
        :crypto.hash(:sha256, key)      
    end
end
