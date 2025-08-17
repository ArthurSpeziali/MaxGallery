defmodule MaxGallery.Request do
  alias MaxGallery.Server.LiveServer

  @spec url_fetch(atom()) :: String.t()
  def url_fetch(:acess_token) do
    "https://oauth2.googleapis.com/token"
  end

  def consume_access_token() do
    LiveServer.get(:access_token)
    |> case do
      {expires, token} ->
        NaiveDateTime.after?(
          NaiveDateTime.utc_now(),
          expires
        )
        |> if do
          access_token()
        else
          {:ok, token}
        end

      nil ->
        access_token()
    end
  end

  @spec access_token() :: {:ok, String.t()} | {:error, String.t()}
  def access_token() do
    body =
      %{
        client_id: System.get_env("GMAIL_CLIENT_ID"),
        client_secret: System.get_env("GMAIL_CLIENT_SECRET"),
        refresh_token: System.get_env("GMAIL_REFRESH_TOKEN"),
        grant_type: "refresh_token"
      }
      |> URI.encode_query()

    headers = ["Content-Type": "application/x-www-form-urlencoded"]

    res =
      url_fetch(:acess_token)
      |> HTTPoison.post!(body, headers)

    case res.status_code do
      200 ->
        token =
          Jason.decode!(res.body)
          |> Map.fetch!("access_token")

        expires =
          NaiveDateTime.add(
            NaiveDateTime.utc_now(),
            3000,
            :second
          )

        LiveServer.put(:access_token, {expires, token})

        {:ok, token}

      401 ->
        {:error, "invalid params"}

      400 ->
        {:error, "expired token"}

      _ ->
        {:error, "unknow error"}
    end
  end

end
