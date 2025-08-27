defmodule MaxGallery.Mail do
  alias MaxGallery.Mail.Mailer

  @spec send(template :: struct()) :: pid()
  def send(template) do
    Task.async(Mailer, :deliver, [template])
  end
end
