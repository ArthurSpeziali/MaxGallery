defmodule MaxGallery.Core.Data do
    use Ecto.Schema
    alias MaxGallery.Core.Group


    ## These `@primary_key` and `foreign_key_type` are nescessary for the Mongo binary_id compatibility.
    @primary_key {:id, :binary_id, autogenerate: true}
    @foreign_key_type :binary_id
    schema "cyphers" do
        field :file_id, :binary_id
        field :name, :binary
        field :name_iv, :binary
        field :blob_iv, :binary
        field :ext, :string, default: ".txt"
        field :msg, :string
        field :msg_iv, :string

        belongs_to :group, Group
        timestamps()
    end


    def changeset(model, params) do
        Ecto.Changeset.cast(model, params, [:name, :name_iv, :file_id, :blob_iv, :ext, :group_id, :msg, :msg_iv])
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
