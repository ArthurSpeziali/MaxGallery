defmodule MaxGallery.Repo.Migrations.AddMsgivField do
    use Ecto.Migration

    def change() do
        alter table("cyphers") do
            add :msg_iv, :string, null: false
        end
    end
end
