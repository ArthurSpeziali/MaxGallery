defmodule MaxGallery.Mail.Template do
  import Swoosh.Email
  alias MaxGallery.Variables

  def custom(dest, text, subject \\ nil, html \\ nil) do
    new()
    |> to(dest)
    |> from({"MaxGallery", Variables.email_user()})
    |> subject(subject || Variables.email_subject())
    |> text_body(text)
    |> html_body(html || text)
  end
end
