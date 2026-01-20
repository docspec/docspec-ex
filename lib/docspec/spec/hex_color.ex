defmodule DocSpec.Spec.HexColor do
  @moduledoc """
  A color value in CSS hex format.

  ## Fields

  * `hex` (required) - A CSS hex color value with # prefix (e.g., '#ff0000' or '#FF0000').
  """

  use DocSpec.Spec.Schema

  typed_embedded_schema null: false do
    # A CSS hex color value with # prefix (e.g., '#ff0000' or '#FF0000').
    field :hex, :string
  end

  @doc """
  Validates and casts the given attributes into a changeset.

  Ensures all required fields are present, embedded schemas are properly
  cast, and field values conform to their expected types and constraints.
  """
  def changeset(schema, attrs) do
    schema
    |> cast(attrs, [:hex], @cast_opts)
    |> validate_required([:hex])
    |> validate_format(:hex, ~r/^#[0-9a-fA-F]{6}$/)
  end
end
