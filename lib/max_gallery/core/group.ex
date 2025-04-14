defmodule MaxGallery.Core.Group do
    use Ecto.Schema

    schema "groups" do
        field :name, :string, default: "New Group"
        timestamps()
    end

    def changeset(model, params) do
        Ecto.Changeset.cast(model, params, [:name])
    end
end
