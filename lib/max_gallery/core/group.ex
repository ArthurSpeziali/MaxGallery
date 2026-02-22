defmodule MaxGallery.Core.Group do
  use Ecto.Schema
  alias MaxGallery.Core.Cypher
  alias MaxGallery.Core.User

  schema "groups" do
    field :file, :integer, default: 0
    field :name_iv, :binary
    field :name, :binary
    field :msg_iv, :binary
    field :msg, :binary

    belongs_to :user, User, type: :binary_id
    belongs_to :group, __MODULE__

    ## `group_id` can be inserted in both structs (Cyphers and Groups). that represents your parent folder.
    has_many :cypher, Cypher
    has_many :subgroup, __MODULE__

    timestamps()
  end

  def changeset(model, params) do
    Ecto.Changeset.cast(model, params, [:file, :name, :name_iv, :group_id, :msg, :msg_iv, :user_id])
  end

  def fields() do
    %__MODULE__{}
    |> Map.drop([
      :__struct__,
      :__meta__,
      :group,
      :subgroup
    ])
    |> Map.keys()
  end
end
