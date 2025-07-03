defmodule MaxGallery.Core.User do
    use Ecto.Schema
    alias MaxGallery.Core.Cypher


    schema "users" do
        field :name, :string
        field :passhash, :binary
        field :email, :string

        has_many :cypher, Cypher
        timestamps()
    end


    def changeset(model, params) do
        Ecto.Changeset.cast(model, params, [:name, :passhash, :email])
    end

    ## Return all `Cypher` fields.
    def fields() do
        %__MODULE__{}
        |> Map.drop([
            :__struct__,
            :__meta__,
            :cypher
        ]) |> Map.keys()
    end
end
