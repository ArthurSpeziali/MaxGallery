defmodule MaxGallery.Validate do
  alias MaxGallery.Context
  @type response :: :ok | {:error, String.t()}

  @spec int!(str :: binary()) :: integer()
  def int!(str) do
    if is_binary(str) do
      String.to_integer(str)
    else
      str
    end
  end

  @spec int(str :: binary()) :: integer() | nil
  def int(str) do
    case Integer.parse(str) do
      {int, ""} -> int
      _ -> nil
    end
  end

  @spec input!(str :: binary()) :: binary()
  def input!(str) do
    String.downcase(str)
    |> String.trim()
  end

  @spec email(str :: binary()) :: response()
  def email(str) do
    cond do
      !String.printable?(str) ->
        {:error, "Your String is not valid!"}

      String.length(str) > 128 ->
        {:error, "Your E-mail is too long (more than 128)."}

      !EmailChecker.valid?(str) ->
        {:error, "Your E-mail is not valid!"}

      true ->
        :ok
    end
  end

  @spec passwd(str :: binary()) :: response()
  def passwd(str) do
    cond do
      !String.printable?(str) ->
        {:error, "Your String is not valid!"}

      String.length(str) < 6 ->
        {:error, "Your Password must contain in the minimum 6 characters."}

      String.length(str) > 32 ->
        {:error, "Your Password is too long! (more than 32)."}

      String.contains?(str, " ") ->
        {:error, "Your Password must not contain spaces!"}

      true ->
        :ok
    end
  end

  @spec name(str :: binary()) :: response()
  def name(str) do
    cond do
      !String.printable?(str) ->
        {:error, "Your String is not valid!"}

      String.length(str) < 3 ->
        {:error, "Your Name must contain in the minimum 3 characters."}

      String.length(str) > 32 ->
        {:error, "Your Name is too long! (more than 32)."}

      true ->
        :ok
    end
  end

  ## Check if the email alredy been taken
  @spec email?(str :: binary()) :: boolean()
  def email?(str) do
    case Context.user_get(nil, email: str) do
      {:ok, _querry} ->
        false

      {:error, "not found"} ->
        true
    end
  end
end
