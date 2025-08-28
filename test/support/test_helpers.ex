defmodule MaxGallery.TestHelpers do
  alias MaxGallery.Variables
  alias MaxGallery.Context
  @tmp_path Variables.tmp_dir() <> "test/"

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
      {:ok, user_id} -> user_id
      {:error, _reason} -> default_test_user()
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
    path = @tmp_path <> "#{System.unique_integer([:positive])}"
    File.mkdir_p!(@tmp_path)
    File.write!(path, content, [:write])
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
    File.rm_rf!(@tmp_path)
  end
end
