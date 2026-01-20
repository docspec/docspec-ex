defmodule DocSpec.Spec.OrderedList do
  @moduledoc """
  A numbered list where order matters. Equivalent to HTML `<ol>` element.

  ## Fields

  * `start` - An integer to start counting from for the list items.
  * `reversed` - Specifies that the list's items are in reverse order, numbered from high to low.
  * `style_type` - The style type of the ordered list marker.
  * `children` (required) - Allowed types: `DocSpec.Spec.ListItem`.
  * `id` (required)
  * `type` - Always `"https://alpha.docspec.io/OrderedList"`.
  """

  use DocSpec.Spec.Schema, type: "https://alpha.docspec.io/OrderedList"

  typed_embedded_schema null: false do
    # An integer to start counting from for the list items.
    field :start, :integer, default: 1
    # Specifies that the list's items are in reverse order, numbered from high to low.
    field :reversed, :boolean, default: false
    # The style type of the ordered list marker.
    field :style_type, :string, default: "decimal"
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
    |> cast(attrs, [:start, :reversed, :style_type, :id, :type], @cast_opts)
    |> cast_embed(:children, @cast_opts ++ [required: true])
    |> validate_required([:id])
    |> validate_inclusion(:type, [@resource_type])
    |> validate_uuid()
    |> validate_inclusion(:style_type, [
      "decimal",
      "lower-alpha",
      "upper-alpha",
      "lower-roman",
      "upper-roman"
    ])
  end
end
