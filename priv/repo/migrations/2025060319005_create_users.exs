defmodule MaxGallery.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change() do
    execute("CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\"")

    create table("users", primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("uuid_generate_v4()")
      add :name, :string, size: 32, null: false
      add :passhash, :binary, null: false
      add :email, :string, size: 128, null: false

      timestamps()
    end

    create unique_index("users", [:email])
  end
end
