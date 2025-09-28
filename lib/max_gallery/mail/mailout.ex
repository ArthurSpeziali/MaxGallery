defmodule MaxGallery.Mailout do
  alias MaxGallery.Mail.Mailer
  require Logger
  @type email_t() :: %Swoosh.Email{}

  @spec send(template :: email_t()) :: Task.t()
  def send(template) do
    Task.async(fn -> Mailer.deliver(template) end)
  end

  @spec response(task :: Task.t(), email :: String.t()) :: :ok | {:error, String.t()}
  def response(task, email) do
    res = 
      try do 
        Task.await(task, 45_000)
      rescue 
        _e ->
          {:error, "timeout error"}
      else 
        value ->
          value
      end

    case res do
      {:ok, _} ->
        Logger.debug("Succeful email sendend to '#{email}'")
        :ok

      {:error, "timeout error"} ->
        Logger.debug("Timeout email sendend to '#{email}'")
        {:error, "timeout error"} 

      {:error, {_code, map}} ->
        reason = map["errors"] 
                 |> List.first() 
                 |> Map.get("message")

        Logger.debug("Error email sendend to '#{email}, \nwith reason: #{reason}'")
        {:error, reason}
    end
  end
end
