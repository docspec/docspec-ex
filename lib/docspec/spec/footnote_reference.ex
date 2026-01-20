defmodule DocSpec.Spec.FootnoteReference do
  @moduledoc """
  A reference to a footnote, displayed as a small number or symbol in the text.

  ## Fields

  * `resource_id` (required) - Identifier of the Footnote being referenced.
  * `id` (required)
  * `type` - Always `"https://alpha.docspec.io/FootnoteReference"`.
  """

  use DocSpec.Spec.Schema, type: "https://alpha.docspec.io/FootnoteReference"

  typed_embedded_schema null: false do
    # Identifier of the Footnote being referenced.
    field :resource_id, :string
    field :id, :string
    field :type, :string, default: @resource_type
  end

  @doc """
  Validates and casts the given attributes into a changeset.

  Ensures all required fields are present, embedded schemas are properly
  cast, and field values conform to their expected types and constraints.
  """
  def changeset(schema, attrs) do
    schema
    |> cast(attrs, [:resource_id, :id, :type], @cast_opts)
    |> validate_required([:id])
    |> validate_length(:resource_id, min: 1)
    |> validate_inclusion(:type, [@resource_type])
    |> validate_uuid()
  end
end
