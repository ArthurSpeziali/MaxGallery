defmodule MaxGallery.Repo.Migrations.InsertGroupTimestamps do
    use Ecto.Migration

    def change() do
        alter table("groups") do

            timestamps()
        end
    end
end
