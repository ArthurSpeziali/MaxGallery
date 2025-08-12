defmodule MaxGallery.Repo.Migrations.CreateChunks do
    use Ecto.Migration

    def change() do
        create table("chunks") do
            add :cypher_id, references("cyphers", on_delete: :delete_all)
            add :blob, :binary, null: false
            add :index, :integer, null: false

            timestamps()
        end
    end
end
