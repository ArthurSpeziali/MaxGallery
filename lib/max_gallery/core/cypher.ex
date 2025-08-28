defmodule MaxGallery.Core.Cypher do
  use Ecto.Schema
  alias MaxGallery.Core.Group
  alias MaxGallery.Core.User

  @foreign_key_type :binary_id
  schema "cyphers" do
    field :name, :binary
    field :name_iv, :binary
    field :blob_iv, :binary
    field :ext, :string, default: ".txt"
    field :msg, :string
    field :msg_iv, :string
    field :length, :integer, default: 0

    belongs_to :user, User
    belongs_to :group, Group, type: :integer
    # Chunks removed - files now stored directly in S3
    timestamps()
  end

  def changeset(model, params) do
    Ecto.Changeset.cast(model, params, [
      :name,
      :name_iv,
      :blob_iv,
      :ext,
      :group_id,
      :msg,
      :msg_iv,
      :user_id
    ])
  end

  ## Return all `Cypher` fields.
  def fields() do
    %__MODULE__{}
    |> Map.drop([
      :__struct__,
      :__meta__,
      :group,
      :chunck,
      :user
    ])
    |> Map.keys()
  end
end
