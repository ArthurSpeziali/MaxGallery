defmodule MaxGallery.Repo.Migrations.ForeignGroupData do
    use Ecto.Migration

    def change() do
        alter table("cyphers") do
            add :group_id, references("groups", on_delete: :nilify_all)
        end
    end
end
