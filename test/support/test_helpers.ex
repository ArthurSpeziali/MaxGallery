defmodule MaxGallery.TestHelpers do
  alias MaxGallery.Context
  # @tmp_path Variables.tmp_dir() <> "test/"  # Commented out as it's not used

  @moduledoc """
  Helper functions for tests to create test data quickly without external dependencies.
  """

  @doc """
  Creates a test user and returns the user ID.
  """
  def create_test_user(email \\ nil) do
    email = email || "test_user_#{System.unique_integer([:positive])}@example.com"
    name = "Test User"
    password = "test_password_123"

    case Context.user_insert(name, email, password) do
      {:ok, user_id} ->
        user_id

      {:error, "email alredy been taken"} ->
        # If email already exists, try to get the user
        case Context.user_get(nil, email: email) do
          {:ok, user} -> user.id
          # Try with a new email
          _ -> create_test_user()
        end
    end
  end

  @doc """
  Creates a test user in the database and returns the user ID.
  """
  def create_real_test_user do
    email = "test_user_#{System.unique_integer([:positive])}@example.com"
    name = "Test User"
    password = "test_password_123"

    case Context.user_insert(name, email, password) do
      {:ok, user_id} ->
        user_id

      {:error, reason} ->
        # If user creation fails, raise an error instead of returning a fake UUID
        raise "Failed to create test user: #{reason}"
    end
  end

  @doc """
  Returns a default test user ID for tests.
  """
  def default_test_user do
    # Generate a valid UUID for testing
    Ecto.UUID.generate()
  end

  @doc """
  Creates test content without creating actual files.
  Returns the content directly for use in tests.
  """
  def create_test_content(content \\ "Lorem ipsum dolor sit amet, consectetur adipiscing elit.") do
    content
  end

  @doc """
  Creates a temporary file with test content.
  Use this only when you actually need a file path.
  """
  def create_temp_file(content \\ nil) do
    content = content || create_test_content()
    # Use System.tmp_dir() instead of custom path to avoid conflicts
    path = System.tmp_dir!() <> "/max_gallery_test_#{System.unique_integer([:positive])}.txt"
    File.write!(path, content)
    path
  end

  @doc """
  Creates test data for a cypher without file dependencies.
  """
  def create_test_cypher_data(name \\ "test_file", ext \\ ".txt") do
    %{
      name: name,
      ext: ext,
      content: create_test_content()
    }
  end

  @doc """
  Cleanup temporary test files.
  """
  def cleanup_temp_files do
    # Clean up individual files instead of entire directory
    case File.ls(System.tmp_dir!()) do
      {:ok, files} ->
        files
        |> Enum.filter(&String.starts_with?(&1, "max_gallery_test_"))
        |> Enum.each(fn file ->
          path = Path.join(System.tmp_dir!(), file)
          File.rm(path)
        end)
      _ -> :ok
    end
  end
end
