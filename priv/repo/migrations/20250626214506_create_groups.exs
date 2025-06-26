defmodule MaxGallery.Repo.Migrations.CreateGroups do
    use Ecto.Migration

    def change() do
        create table("groups") do
            add :group_id, references("groups", on_delete: :delete_all)
            add :name, :binary, null: false
            add :name_iv, :binary, null: false
            add :msg, :binary, null: false
            add :msg_iv, :binary, null: false

            timestamps()
        end

        create unique_index("groups", [:name, :name_iv])
    end
end
