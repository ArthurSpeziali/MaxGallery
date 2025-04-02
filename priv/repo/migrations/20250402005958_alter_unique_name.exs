defmodule MaxGallery.Repo.Migrations.AlterUniqueName do
    use Ecto.Migration

    def change() do
        alter table("cyphers") do
            add :ext, :string, null: false, default: ".txt"
        end

        create unique_index("cyphers", [:name])
    end
end
