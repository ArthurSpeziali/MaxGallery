defmodule MaxGallery.Phantom do
    alias MaxGallery.Encrypter
    alias MaxGallery.Core.Cypher.Api

    @moduledoc """
    Provides validation and integrity checking for encrypted data in MaxGallery.

    This module serves as a "phantom" validation layer that works around the limitations
    of the cryptographic system by:

    - Adding verifiable metadata to encrypted records
    - Validating decryption integrity
    - Handling binary data encoding
    - Providing system health checks

    Key functions include:

    ## Validation & Security
    - `valid?/2` - Verifies if decrypted data matches expected patterns
    - `insert_line?/1` - Checks if system is in valid state for new entries

    ## Cypher Handling
    - `validate_bin/1` - Ensures binary data is safely printable
    - `encode_bin/1` - Recursively prepares binary data for storage/display

    ## Phantom Metadata
    - `get_text/0` - Provides the canonical validation marker
    - Acts as checksum for decryption integrity

    ## Purpose
    Since the encryption system can't intrinsically detect successful decryption,
    this module adds verifiable "phantom" metadata that:
    - Confirms decryption was successful
    - Validates the encryption key was correct
    - Maintains system integrity
    - Prevents corruption of encrypted data
    """


    @doc """
    Validates and sanitizes binary data for safe display/storage.

    ## Parameters
    - `binary` - The binary data to validate

    ## Returns
    - The original binary if it contains only printable characters
    - Base64 encoded string if binary contains non-printable characters

    ## Behavior
    1. Checks if binary is printable using `String.printable?/1`
    2. Returns unchanged if fully printable
    3. Applies Base64 encoding if contains non-printable chars

    ## Use Cases
    - Preparing encrypted data for JSON serialization
    - Safely displaying binary content in UIs
    - Validating data before database insertion
    - Ensuring logs contain only printable characters

    ## Notes
    - Protects against encoding/display issues
    - Preserves data integrity for non-printable binaries
    - Does not modify the actual stored/encrypted data
    - Pure function with no side effects
    """
    @spec validate_bin(binary :: binary()) :: String.t()
    def validate_bin(binary) do
        if String.printable?(binary) do
            binary
        else
            Base.encode64(binary)
        end 
    end


    @doc """
    Recursively encodes binary data within content structures for safe handling.

    ## Parameters
    - `contents` - Can be either:
      - A single content item (map)
      - List of content items

    ## Returns
    - Transformed content with all binaries validated:
      - `name` field always processed
      - `blob` field processed if present
    - Returns same structure type as input

    ## Behavior
    1. Normalizes input to list (if single item)
    2. Processes each content item:
       - Validates `name` field using `validate_bin/1`
       - Validates `blob` field if present
    3. Returns processed items in original structure

    ## Use Cases
    - Preparing content for API responses
    - Sanitizing data before logging
    - Validating content before serialization

    ## Notes
    - Preserves all non-binary fields unchanged
    - Handles nested content structures
    - Pure function with no side effects
    - Maintains data structure integrity
    - Safe to use on already-validated content
    """
    @spec encode_bin(contents :: Context.querry()) :: Context.querry()
    def encode_bin(contents) when is_list(contents) do
        Enum.map(contents, fn item -> 
            new_content = Map.update!(item, :name, &validate_bin/1)
            
            if new_content[:blob] do
                Map.update!(new_content, :blob, &validate_bin/1)
            else
                new_content
            end
        end)
    end
    def encode_bin(content) do
       encode_bin([content]) 
    end


    @doc """
    Returns the canonical validation marker used for encryption integrity checks.

    ## Returns
    - String "encrypted_data" - The predefined verification text

    ## Purpose
    Serves as a known plaintext value that:
    - Gets encrypted and stored with records
    - Allows verification of successful decryption
    - Acts as a checksum for encryption integrity

    ## Usage
    1. Encrypted alongside real data
    2. Stored in the `msg` field with its IV
    3. Used by `valid?/2` to verify decryption

    ## Notes
    - Constant value ensures predictable verification
    - Simple string minimizes verification overhead
    - Never modified to maintain system consistency
    - Acts as "phantom" metadata for validation
    """
    @spec get_text() :: String.t()
    def get_text(), do: "encrypted_data"

    @doc """
    Validates whether data was decrypted successfully by checking the phantom marker.

    ## Parameters
    - `%{msg_iv: msg_iv, msg: msg}` - Map containing:
      - `msg_iv`: Initialization vector for the message
      - `msg`: Encrypted phantom validation text
    - `key` - Encryption key to attempt decryption with

    ## Returns
    - `true` if decrypted text matches expected phantom marker
    - `false` if:
      - Decryption fails
      - Wrong key used
      - Cypher corrupted
      - Invalid IV

    ## Behavior
    1. Decrypts the stored phantom message using provided key
    2. Compares result against expected validation text
    3. Returns boolean indicating validation success

    ## Notes
    - Critical for verifying decryption integrity
    - Acts as checksum for the encryption process
    - Requires exact key/IV used during encryption
    - Safe to call on any encrypted record
    - Fast-fails if decryption is unsuccessful
    """
    @spec valid?(map(), key :: String.t()) :: boolean()
    def valid?(%{msg_iv: msg_iv, msg: msg}, key) do
        {:ok, dec_cypher} = Encrypter.decrypt({msg_iv, msg}, key)

        dec_cypher == get_text()
    end


    @doc """
    Determines if the system is in a valid state to insert new encrypted records.

    ## Parameters
    - `key` - The current encryption key to validate against

    ## Returns
    - `true` if either:
      - Cypherbase is empty (no existing records)
      - Existing records decrypt properly with current key
    - `false` if existing records fail to decrypt with current key

    ## Behavior
    1. Checks for first record in database
    2. If no records exist (`{:error, "not found"}`), returns true
    3. If records exist, validates them using `valid?/2`
    4. Returns validation result

    ## Purpose
    - Prevents inserting data with wrong encryption key
    - Maintains database consistency
    - Acts as safety check before write operations

    ## Notes
    - Critical for preventing data corruption
    - Fast path when database is empty
    - Uses phantom validation pattern
    - Should be checked before all insert operations
    """
    @spec insert_line?(key :: String.t()) :: boolean()
    def insert_line?(key) do
        case Api.first() do
            {:error, "not found"} -> true
            {:ok, querry} -> valid?(querry, key)
        end
    end

end
