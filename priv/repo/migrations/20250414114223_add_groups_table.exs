defmodule MaxGallery.Repo.Migrations.AddGroupsTable do
    use Ecto.Migration

    def change() do
        create table("groups") do
            add :name, :string, default: "New Group"
        end
    end
end
