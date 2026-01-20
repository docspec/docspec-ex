defmodule DocSpec.Spec.AssetSource do
  @moduledoc """
  A reference to an embedded asset by its identifier.

  ## Fields

  * `asset_id` (required) - The identifier of an Asset in this document.
  """

  use DocSpec.Spec.Schema

  typed_embedded_schema null: false do
    # The identifier of an Asset in this document.
    field :asset_id, :string
  end

  @doc """
  Validates and casts the given attributes into a changeset.

  Ensures all required fields are present, embedded schemas are properly
  cast, and field values conform to their expected types and constraints.
  """
  def changeset(schema, attrs) do
    schema
    |> cast(attrs, [:asset_id], @cast_opts)
    |> validate_length(:asset_id, min: 1)
  end
end
