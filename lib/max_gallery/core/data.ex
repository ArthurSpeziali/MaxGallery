defmodule MaxGallery.Core.Data do
    use Ecto.Schema

    schema "cyphers" do
        field :name, :string 
        field :blob, :binary
        field :ext, :string, default: ".txt"

        timestamps()
    end

    def changeset(model, params) do
        Ecto.Changeset.cast(model, params, [:name, :blob])
        |> Ecto.Changeset.validate_required([:name])
    end
end
