defmodule MaxGallery.Validate do
  @type response :: :ok | {:error, String.t()}

  @spec int!(str :: binary()) :: integer()
  def int!(str) do
    if is_binary(str) do
      String.to_integer(str)
    else
      str
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

      String.length(str) > 32 ->
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

      String.length(str) > 32 ->
        {:error, "Your Password is too long! (more than 32)."}

      String.contains?(str, " ") ->
        {:error, "Your Password must not contain spaces!"}

      true ->
        :ok
    end
  end
end
