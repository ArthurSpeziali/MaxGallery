defmodule MaxGallery.Mail do
  alias MaxGallery.Mail.Mailer
  require Logger

  @spec send(template :: struct()) :: pid()
  def send(template) do
    Task.async(Mailer, :deliver, [template])
  end

  @spec respose(task :: pid(), email :: binary()) :: no_return()
  def respose(task, email) do
    res = Task.await(task)

    case res do
      {:ok, _} ->
        Logger.info("Succeful email sendend to '#{email}'")

      {:error, _} ->
        Logger.info("Error email sendend to '#{email}'")
    end
  end
end
