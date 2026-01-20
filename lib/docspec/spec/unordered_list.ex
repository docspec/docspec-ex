defmodule DocSpec.Spec.UnorderedList do
  @moduledoc """
  A bulleted list where order does not matter. Equivalent to HTML `<ul>` element.

  ## Fields

  * `style_type` - The style type of the unordered list marker.
  * `children` (required) - Allowed types: `DocSpec.Spec.ListItem`.
  * `id` (required)
  * `type` - Always `"https://alpha.docspec.io/UnorderedList"`.
  """

  use DocSpec.Spec.Schema, type: "https://alpha.docspec.io/UnorderedList"

  typed_embedded_schema null: false do
    # The style type of the unordered list marker.
    field :style_type, :string, default: "disc"
    embeds_many :children, DocSpec.Spec.ListItem
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
    |> cast(attrs, [:style_type, :id, :type], @cast_opts)
    |> cast_embed(:children, @cast_opts ++ [required: true])
    |> validate_required([:id])
    |> validate_inclusion(:type, [@resource_type])
    |> validate_uuid()
    |> validate_inclusion(:style_type, ["disc", "circle", "square"])
  end
end
