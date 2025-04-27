defmodule MaxGallery.Core.Data do
    use Ecto.Schema
    alias MaxGallery.Core.Group

    schema "cyphers" do
        field :name, :binary
        field :name_iv, :binary
        field :blob, :binary
        field :blob_iv, :binary
        field :ext, :string, default: ".txt"
        field :msg, :string
        field :msg_iv, :string

        belongs_to :group, Group
        timestamps()
    end


    def changeset(model, params) do
        Ecto.Changeset.cast(model, params, [:name, :name_iv, :blob, :blob_iv, :ext, :group_id])
    end

    def fields() do
        %__MODULE__{}
        |> Map.delete(:__struct__)
        |> Map.delete(:__meta__)
        |> Map.delete(:group)
        |> Map.keys()
    end
end
