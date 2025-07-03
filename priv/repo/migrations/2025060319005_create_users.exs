defmodule MaxGallery.Repo.Migrations.CreateUsers do
    use Ecto.Migration

    def change() do
        create table("users") do
            add :name, :string, size: 32, null: false
            add :passhash, :binary, null: false
            add :email, :string, size: 128, null: false

            timestamps()
        end

        create unique_index("users", [:email])
    end
end
