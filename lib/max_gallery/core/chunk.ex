defmodule MaxGallery.Core.Chunk do
  use Ecto.Schema
  alias MaxGallery.Core.Cypher

  schema "chunks" do
    field :blob, :binary
    field :index, :integer
    field :length, :integer, default: 0

    belongs_to :cypher, Cypher
    timestamps()
  end

  def changeset(model, params) do
    Ecto.Changeset.cast(model, params, [:blob, :index, :length, :cypher_id])
  end

  def fields() do
    %__MODULE__{}
    |> Map.drop([
      :__struct__,
      :__meta__,
      :cypher
    ])
    |> Map.keys()
  end
end
