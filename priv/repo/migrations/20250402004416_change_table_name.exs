defmodule MaxGallery.Repo.Migrations.ChangeTableName do
    use Ecto.Migration

    def up() do
        rename table("datas"), to: table("cyphers")
    end

    def down() do
        rename table("cyphers"), to: table("datas")
    end
end
