defmodule MaxGallery.Repo.Migrations.CreateDataTable do
    use Ecto.Migration

    def change() do
        create table("datas") do
            add :name, :string, null: false
            add :blob, :blob, null: false

            timestamps()
        end
    end
end
