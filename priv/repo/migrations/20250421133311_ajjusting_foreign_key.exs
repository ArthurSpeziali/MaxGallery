defmodule MaxGallery.Repo.Migrations.AjjustingForeignKey do
    use Ecto.Migration

    def change() do
        alter table("cyphers") do
            add :group_id2, references("groups", on_delete: :delete_all)

            remove :group_id
        end

        rename table("cyphers"), :group_id2, to: :group_id

        alter table("groups") do
            add :parent_id, references("groups", on_delete: :delete_all)
        end
    end
end
