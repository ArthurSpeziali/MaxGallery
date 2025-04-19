defmodule MaxGallery.Core.Group do
    use Ecto.Schema
    alias MaxGallery.Core.Data

    schema "groups" do
        field :name_iv, :binary
        field :name, :binary
        field :msg_iv, :binary
        field :msg, :binary

        has_many :cypher, Data
        timestamps()
    end

    def changeset(model, params) do
        Ecto.Changeset.cast(model, params, [:name, :name_iv])
    end
end
