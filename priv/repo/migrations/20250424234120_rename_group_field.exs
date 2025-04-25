defmodule MaxGallery.Repo.Migrations.RenameGroupField do
    use Ecto.Migration

    def change() do
        rename table("groups"), :parent_id, to: :group_id
    end
end
