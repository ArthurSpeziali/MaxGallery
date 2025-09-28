defmodule MaxGallery.Mail do
  alias MaxGallery.Mail.Mailer
  require Logger
  @type email_t() :: %Swoosh.Email{}

  @spec send(template :: email_t()) :: Task.t()
  def send(template) do
    [{_, email}] = template.to 

    spawn(fn -> 
      res = Mailer.deliver(template)

      case res do 
        {:ok, _} ->
          Logger.info("Succeful email sendend to '#{email}'")
          :ok

        {:error, {_code, map}} ->
          reason = map["errors"] 
                   |> List.first() 
                   |> Map.get("message")

          Logger.info("Error email sendend to '#{email}, \nwith reason: #{reason}'")
          {:error, reason}
      end

    end)
  end

end
