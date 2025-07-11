defmodule MaxGallery.Request do
  @spec url_fetch(atom()) :: term()
  def url_fetch(:acess_token) do
    "https://oauth2.googleapis.com/token"
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
        {:ok,
         Jason.decode!(res.body)
         |> Map.fetch!("access_token")}

      code when code in [400, 401] ->
        {:error, "invalid params"}

      _ ->
        {:error, "unknow error"}
    end
  end
end
