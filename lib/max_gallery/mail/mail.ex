defmodule MaxGallery.Mail do
  alias MaxGallery.Mail.Mailer
  @type email_t :: %Swoosh.Email{}

  @spec send(template :: email_t()) :: Task.t()
  def send(template) do
    Task.async(Mailer, :deliver, [template])
  end
end
