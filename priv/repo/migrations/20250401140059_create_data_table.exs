defmodule MaxGallery.Repo.Migrations.CreateDataTable do
    use Ecto.Migration

    def change() do
        create table("cyphers") do
            add :name, :blob, null: false
            add :name_iv, :blob, null: false, default: ""
            add :blob, :blob, null: false
            add :blob_iv, :blob, null: false, default: ""
            add :ext, :string, null: false, default: ".txt"

            timestamps()
        end

        create unique_index("cyphers", [:name])
    end
end
