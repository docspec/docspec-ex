defmodule DocSpec.Spec.ThematicBreak do
  @moduledoc """
  A thematic break representing a shift in topic or section. Equivalent to HTML `<hr>` element.

  ## Fields

  * `id` (required)
  * `type` - Always `"https://alpha.docspec.io/ThematicBreak"`.
  """

  use DocSpec.Spec.Schema, type: "https://alpha.docspec.io/ThematicBreak"

  typed_embedded_schema null: false do
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
    |> cast(attrs, [:id, :type], @cast_opts)
    |> validate_required([:id])
    |> validate_inclusion(:type, [@resource_type])
    |> validate_uuid()
  end
end
