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
        Ecto.Changeset.cast(model, params, [:name, :name_iv, :blob_iv, :blob, :ext, :group_id, :msg, :msg_iv])
    end

    ## Return all `Data` fields.
    def fields() do
        %__MODULE__{}
        |> Map.drop([
            :__struct__,
            :__meta__,
            :group
        ]) |> Map.keys()
    end
end
