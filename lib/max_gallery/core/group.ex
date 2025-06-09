defmodule MaxGallery.Core.Group do
    use Ecto.Schema
    alias MaxGallery.Core.Data


    @primary_key {:id, :binary_id, autogenerate: true}
    @foreign_key_type :binary_id
    schema "groups" do
        field :name_iv, :binary
        field :name, :binary
        field :msg_iv, :binary
        field :msg, :binary

        has_many :cypher, Data

        belongs_to :group, __MODULE__
        ## `group_id` can be inserted in both structs (Datas and Groups). that represents your parent folder.
        has_many :subgroup, __MODULE__

        timestamps()
    end

    def changeset(model, params) do
        Ecto.Changeset.cast(model, params, [:name, :name_iv, :group_id, :msg, :msg_iv])
    end

    def fields() do
        %__MODULE__{}
        |> Map.delete(:__struct__)
        |> Map.delete(:__meta__)
        |> Map.delete(:group)
        |> Map.delete(:subgroup)
        |> Map.keys()
    end

end
