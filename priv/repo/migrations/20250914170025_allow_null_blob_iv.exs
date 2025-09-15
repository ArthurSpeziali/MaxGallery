defmodule MaxGallery.Repo.Migrations.AllowNullBlobIv do
  use Ecto.Migration

  def change do
    alter table("cyphers") do
      modify :blob_iv, :binary, null: true
    end
  end
end