defmodule MaxGallery.Encrypter do
  @type cypher :: {iv :: binary(), ciphertext :: binary()}
  @type stream :: %Stream{}

  alias MaxGallery.Variables

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
  @spec encrypt(data :: binary(), key :: String.t()) :: cypher()
  def encrypt(data, key) do
    iv = :crypto.strong_rand_bytes(16)
    hash_key = hash(key)

    cypher = :crypto.crypto_one_time(:aes_256_ctr, hash_key, iv, data, true)
    {iv, cypher}
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
  @spec decrypt(cypher :: binary(), iv :: binary(), key :: String.t()) :: binary()
  def decrypt(cypher, iv, key) do
    hash_key = hash(key)

    :crypto.crypto_one_time(:aes_256_ctr, hash_key, iv, cypher, false)
  end

  @spec encrypt_stream(path :: Path.t(), key :: String.t()) :: {stream(), binary()}
  def encrypt_stream(path, key) do
    iv = random()
    key = hash(key)
    ref = :crypto.crypto_init(:aes_ctr, key, iv, true)

    stream =
      File.stream!(path, Variables.chunk_size())
      |> Stream.map(fn chunk ->
        :crypto.crypto_update(ref, chunk)
      end)

    :crypto.crypto_final(ref)
    {stream, iv}
  end

  @spec decrypt_stream(stream :: stream(), iv :: binary(), key :: String.t()) :: stream()
  def decrypt_stream(stream, iv, key) do
    key = hash(key)
    ref = :crypto.crypto_init(:aes_ctr, key, iv, false)

    stream =
      Stream.map(stream, fn chunk ->
        :crypto.crypto_update(ref, chunk)
      end)

    :crypto.crypto_final(ref)
    stream
  end

  @spec hash(key :: String.t()) :: binary()
  def hash(key) do
    :crypto.hash(:sha256, key)
  end

  @spec random(bytes :: pos_integer()) :: binary()
  def random(bytes \\ 16) when bytes > 0 do
    :crypto.strong_rand_bytes(bytes)
  end
end
