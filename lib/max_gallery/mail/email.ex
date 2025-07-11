defmodule MaxGallery.Mail.Email do
  alias MaxGallery.Request
  alias MaxGallery.Mail.Mailer

  def send(%Swoosh.Email{} = template) do
    res = Request.access_token()

    case res do
      {:ok, token} ->
        {:ok, sended} = Mailer.deliver(template, access_token: token)
        {:ok, sended.id}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
