defmodule MaxGallery.Repo do
  use Ecto.Repo,
    otp_app: :max_gallery,
    adapter: Mongo.Ecto
end
