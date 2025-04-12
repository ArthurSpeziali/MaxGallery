defmodule MaxGallery.Repo.Migrations.AddMsgField do
    use Ecto.Migration

    def change() do
        alter table("cyphers") do
            add :msg, :string, null: false
        end
    end
end
