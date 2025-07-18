defmodule MaxGallery.Mail.Email do
  alias MaxGallery.Request
  alias MaxGallery.Mail.Mailer

  def send(%Swoosh.Email{} = template) do
    res = Request.consume_access_token()

    case res do
      {:ok, token} ->
        spawn_link(Mailer, :deliver, [template, [access_token: token]])

      {:error, reason} ->
        {:error, reason}
    end
  end
end
