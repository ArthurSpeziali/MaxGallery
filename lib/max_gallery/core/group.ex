defmodule MaxGallery.Core.Group do
    use Ecto.Schema
    alias MaxGallery.Core.Data

    schema "groups" do
        field :name_iv, :binary
        field :name, :binary
        field :msg_iv, :binary
        field :msg, :binary

        has_many :cypher, Data

        belongs_to :parent, __MODULE__
        has_many :group, __MODULE__, foreign_key: :parent_id

        timestamps()
    end

    def changeset(model, params) do
        Ecto.Changeset.cast(model, params, [:name, :name_iv])
    end

    def fields() do
        %__MODULE__{}
        |> Map.delete(:__struct__)
        |> Map.delete(:__meta__)
        |> Map.delete(:group)
        |> Map.delete(:parent)
        |> Map.keys()
    end

end
