defmodule MaxGallery.Repo.Migrations.CreateCyphers do
    use Ecto.Migration

    def change() do
        create table("cyphers") do
            add :group_id, references("groups", on_delete: :delete_all)
            add :name, :binary, null: false
            add :name_iv, :binary, null: false
            add :blob_iv, :binary, null: false
            add :ext, :string, size: 32, default: ".txt"
            add :msg, :binary, null: false
            add :msg_iv, :binary, null: false

            timestamps()
        end

        create unique_index("cyphers", [:name, :name_iv])
    end
end
