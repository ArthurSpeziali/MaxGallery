defmodule MaxGallery.Core.Data do
    use Ecto.Schema

    schema "cyphers" do
        field :name, :binary
        field :name_iv, :binary
        field :blob, :binary
        field :blob_iv, :binary
        field :ext, :string, default: ".txt"

        timestamps()
    end

end
