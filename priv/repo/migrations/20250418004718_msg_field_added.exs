defmodule MaxGallery.Repo.Migrations.MsgFieldAdded do
    use Ecto.Migration

    def change() do
        alter table("groups") do
            add :msg, :blob, null: false
            add :msg_iv, :blob, null: false
        end
    end
end
