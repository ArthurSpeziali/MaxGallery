defmodule MaxGallery.Core.Group do
    use Ecto.Schema

    schema "groups" do
        field :name_iv, :binary
        field :name, :binary

        timestamps()
    end

    def changeset(model, params) do
        Ecto.Changeset.cast(model, params, [:name, :name_iv])
    end
end
