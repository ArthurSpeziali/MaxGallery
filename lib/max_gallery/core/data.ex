defmodule MaxGallery.Core.Data do
    use Ecto.Schema

    schema "cyphers" do
        field :name, :binary
        field :name_iv, :binary
        field :blob, :binary
        field :blob_iv, :binary
        field :ext, :string, default: ".txt"
        field :msg, :string
        field :msg_iv, :string

        timestamps()
    end


    def changeset(model, params) do
        Ecto.Changeset.cast(model, params, [:name, :name_iv, :blob, :blob_iv, :ext])
    end

    def fields() do
        %__MODULE__{}
        |> Map.delete(:__struct__)
        |> Map.delete(:__meta__)
        |> Map.keys()
    end
end
