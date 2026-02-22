defmodule MaxGallery.EncrypterTest do
  use ExUnit.Case, async: true
  alias MaxGallery.Encrypter

  describe "encrypt/2 and decrypt/3" do
    test "encrypts and decrypts data successfully" do
      data = "Hello, World!"
      key = "my_secret_key"

      {iv, ciphertext} = Encrypter.encrypt(data, key)

      assert is_binary(iv)
      assert byte_size(iv) == 16
      assert is_binary(ciphertext)
      assert ciphertext != data

      decrypted = Encrypter.decrypt(ciphertext, iv, key)
      assert decrypted == data
    end

    test "encrypts different data with same key produces different ciphertexts" do
      data1 = "Hello, World!"
      data2 = "Hello, World!"
      key = "my_secret_key"

      {iv1, ciphertext1} = Encrypter.encrypt(data1, key)
      {iv2, ciphertext2} = Encrypter.encrypt(data2, key)

      # Different IVs should produce different ciphertexts even with same data
      assert iv1 != iv2
      assert ciphertext1 != ciphertext2

      # But both should decrypt to the same original data
      assert Encrypter.decrypt(ciphertext1, iv1, key) == data1
      assert Encrypter.decrypt(ciphertext2, iv2, key) == data2
    end

    test "encrypts and decrypts binary data" do
      data = <<1, 2, 3, 4, 5, 255, 0, 128>>
      key = "binary_key"

      {iv, ciphertext} = Encrypter.encrypt(data, key)
      decrypted = Encrypter.decrypt(ciphertext, iv, key)

      assert decrypted == data
    end

    test "encrypts and decrypts empty data" do
      data = ""
      key = "empty_key"

      {iv, ciphertext} = Encrypter.encrypt(data, key)
      decrypted = Encrypter.decrypt(ciphertext, iv, key)

      assert decrypted == data
    end

    test "encrypts and decrypts large data" do
      data = String.duplicate("A", 10_000)
      key = "large_data_key"

      {iv, ciphertext} = Encrypter.encrypt(data, key)
      decrypted = Encrypter.decrypt(ciphertext, iv, key)

      assert decrypted == data
    end

    test "different keys produce different results" do
      data = "Same data"
      key1 = "key1"
      key2 = "key2"

      {iv1, ciphertext1} = Encrypter.encrypt(data, key1)
      {iv2, ciphertext2} = Encrypter.encrypt(data, key2)

      # Even with same IV, different keys should produce different results
      # But we can't control IV generation, so we just test that decryption works correctly
      assert Encrypter.decrypt(ciphertext1, iv1, key1) == data
      assert Encrypter.decrypt(ciphertext2, iv2, key2) == data

      # Wrong key should not decrypt correctly
      wrong_decrypt = Encrypter.decrypt(ciphertext1, iv1, key2)
      assert wrong_decrypt != data
    end
  end

  describe "encrypt_stream/2 and decrypt_stream/3" do
    setup do
      # Create a temporary file for testing
      test_content = "This is test content for stream encryption"
      temp_path = System.tmp_dir!() <> "/test_encrypt_stream_#{:rand.uniform(1000)}.txt"
      File.write!(temp_path, test_content)

      on_exit(fn ->
        if File.exists?(temp_path), do: File.rm!(temp_path)
      end)

      %{temp_path: temp_path, test_content: test_content}
    end

    test "encrypts and decrypts file stream", %{temp_path: temp_path, test_content: test_content} do
      key = "stream_key"

      {encrypt_stream, iv} = Encrypter.encrypt_stream(temp_path, key)

      assert is_binary(iv)
      assert byte_size(iv) == 16

      # Collect encrypted chunks
      encrypted_chunks = Enum.to_list(encrypt_stream)
      assert length(encrypted_chunks) > 0

      # Create stream from encrypted chunks and decrypt
      encrypted_stream = Stream.map(encrypted_chunks, & &1)
      decrypted_stream = Encrypter.decrypt_stream(encrypted_stream, iv, key)

      # Collect decrypted data
      decrypted_data = Enum.join(decrypted_stream, "")
      assert decrypted_data == test_content
    end

    test "handles empty file stream", %{} do
      empty_path = System.tmp_dir!() <> "/empty_test_#{:rand.uniform(1000)}.txt"
      File.write!(empty_path, "")

      on_exit(fn ->
        if File.exists?(empty_path), do: File.rm!(empty_path)
      end)

      key = "empty_stream_key"

      {encrypt_stream, iv} = Encrypter.encrypt_stream(empty_path, key)
      encrypted_chunks = Enum.to_list(encrypt_stream)

      encrypted_stream = Stream.map(encrypted_chunks, & &1)
      decrypted_stream = Encrypter.decrypt_stream(encrypted_stream, iv, key)
      decrypted_data = Enum.join(decrypted_stream, "")

      assert decrypted_data == ""
    end
  end

  describe "hash/1" do
    test "produces consistent hash for same input" do
      key = "test_key"
      hash1 = Encrypter.hash(key)
      hash2 = Encrypter.hash(key)

      assert hash1 == hash2
      assert is_binary(hash1)
      assert byte_size(hash1) == 32  # SHA-256 produces 32 bytes
    end

    test "produces different hashes for different inputs" do
      key1 = "key1"
      key2 = "key2"

      hash1 = Encrypter.hash(key1)
      hash2 = Encrypter.hash(key2)

      assert hash1 != hash2
    end

    test "handles empty string" do
      hash = Encrypter.hash("")
      assert is_binary(hash)
      assert byte_size(hash) == 32
    end

    test "handles unicode characters" do
      key = "chave_com_acentos_çãõ"
      hash = Encrypter.hash(key)
      assert is_binary(hash)
      assert byte_size(hash) == 32
    end
  end

  describe "random/1" do
    test "generates random bytes of specified length" do
      bytes = Encrypter.random(16)
      assert is_binary(bytes)
      assert byte_size(bytes) == 16
    end

    test "generates different random bytes on each call" do
      bytes1 = Encrypter.random(16)
      bytes2 = Encrypter.random(16)

      assert bytes1 != bytes2
      assert byte_size(bytes1) == 16
      assert byte_size(bytes2) == 16
    end

    test "generates random bytes with different lengths" do
      bytes8 = Encrypter.random(8)
      bytes32 = Encrypter.random(32)
      bytes64 = Encrypter.random(64)

      assert byte_size(bytes8) == 8
      assert byte_size(bytes32) == 32
      assert byte_size(bytes64) == 64
    end

    test "uses default length of 16 bytes" do
      bytes = Encrypter.random()
      assert byte_size(bytes) == 16
    end

    test "raises error for invalid length" do
      assert_raise FunctionClauseError, fn ->
        Encrypter.random(0)
      end

      assert_raise FunctionClauseError, fn ->
        Encrypter.random(-1)
      end
    end
  end

  describe "integration tests" do
    test "full encryption/decryption cycle with real file" do
      # Create test file
      test_data = """
      This is a multi-line test file
      with various characters: !@#$%^&*()
      and unicode: çãõáéíóú
      and numbers: 1234567890
      """

      temp_path = System.tmp_dir!() <> "/integration_test_#{:rand.uniform(1000)}.txt"
      File.write!(temp_path, test_data)

      on_exit(fn ->
        if File.exists?(temp_path), do: File.rm!(temp_path)
      end)

      key = "integration_test_key"

      # Test stream encryption/decryption
      {encrypt_stream, iv} = Encrypter.encrypt_stream(temp_path, key)
      encrypted_chunks = Enum.to_list(encrypt_stream)

      encrypted_stream = Stream.map(encrypted_chunks, & &1)
      decrypted_stream = Encrypter.decrypt_stream(encrypted_stream, iv, key)
      decrypted_data = Enum.join(decrypted_stream, "")

      assert decrypted_data == test_data

      # Test binary encryption/decryption
      {iv2, ciphertext} = Encrypter.encrypt(test_data, key)
      decrypted_binary = Encrypter.decrypt(ciphertext, iv2, key)

      assert decrypted_binary == test_data
    end
  end
end