defmodule MaxGallery.Mail.Template do
  import Swoosh.Email
  alias MaxGallery.Variables

  defp read_html(name, assigns) do
    Application.app_dir(:max_gallery)
    |> Path.join("priv/static/emails")
    |> Path.join(name <> ".html")
    |> File.read!()
    |> recursive_assigns(assigns)
  end

  defp read_txt(name, assigns) do
    Application.app_dir(:max_gallery)
    |> Path.join("priv/static/emails")
    |> Path.join(name <> ".txt")
    |> File.read!()
    |> recursive_assigns(assigns)
  end

  defp recursive_assigns(text, []), do: text

  defp recursive_assigns(text, [{key, value} | tail]) do
    format_key = "@" <> Atom.to_string(key)

    String.replace(text, format_key, value)
    |> recursive_assigns(tail)
  end

  def custom(dest, subject, text, html) do
    new()
    |> to(dest)
    |> from({"MaxGallery", Variables.email_user()})
    |> subject(subject || Variables.email_subject())
    |> text_body(text)
    |> html_body(html || text)
  end

  def email_verify(dest, code) do
    custom(
      dest,
      "Your Max Gallery verification code",
      read_txt("email_verify", code: code),
      read_html("email_verify", code: code)
    )
  end

  def reset_passwd(dest, link) do
    custom(
      dest,
      "Reset your Max Gallery password",
      read_txt("email_verify", user_name: dest, reset_url: link),
      read_html("email_verify", user_name: dest, reset_url: link)
    )
  end
end
