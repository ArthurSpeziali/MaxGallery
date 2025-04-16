defmodule MaxGallery.Repo.Migrations.AddNameivGroup do
    use Ecto.Migration

    def change() do
        alter table("groups") do
            add :name2, :blob, null: false
            add :name_iv, :blob, null: false

            remove :name
        end

        rename table("groups"), :name2, to: :name
    end
end
