defmodule DocSpec.Spec.Text do
  @moduledoc """
  A run of text with optional styling. The fundamental inline content element.

  ## Fields

  * `text` (required) - The text content.
  * `styles` - Styling applied to the text. Allowed types: `DocSpec.Spec.Styles`.
  * `id` (required)
  * `type` - Always `"https://alpha.docspec.io/Text"`.
  """

  use DocSpec.Spec.Schema, type: "https://alpha.docspec.io/Text"

  typed_embedded_schema null: false do
    # The text content.
    field :text, :string
    # Styling applied to the text.
    embeds_one :styles, DocSpec.Spec.Styles
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
    |> cast(attrs, [:text, :id, :type], @cast_opts)
    |> cast_embed(:styles, @cast_opts)
    |> validate_required([:id])
    |> validate_length(:text, min: 1)
    |> validate_inclusion(:type, [@resource_type])
    |> validate_uuid()
  end
end
