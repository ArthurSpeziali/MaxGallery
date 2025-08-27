defmodule MaxGallery.TestHelpers do
  @moduledoc """
  Helper functions for tests to create test data quickly without external dependencies.
  """

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
    path = "/tmp/max_gallery/tests/test#{System.unique_integer([:positive])}"
    File.mkdir_p!("/tmp/max_gallery/tests")
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
    File.rm_rf!("/tmp/max_gallery/tests")
  end
end