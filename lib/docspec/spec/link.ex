defmodule DocSpec.Spec.Link do
  @moduledoc """
  A hyperlink to an external or internal resource. Equivalent to HTML `<a>` element.

  ## Fields

  * `text` (required) - The text content of the link.
  * `uri` (required) - The URI the link points to.
  * `purpose` - A description of the link's purpose for accessibility.
  * `styles` - Text styling applied to the link. Allowed types: `DocSpec.Spec.Styles`.
  * `id` (required)
  * `type` - Always `"https://alpha.docspec.io/Link"`.
  """

  use DocSpec.Spec.Schema, type: "https://alpha.docspec.io/Link"

  typed_embedded_schema null: false do
    # The text content of the link.
    field :text, :string
    # The URI the link points to.
    field :uri, :string
    # A description of the link's purpose for accessibility.
    field :purpose, :string
    # Text styling applied to the link.
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
    |> cast(attrs, [:text, :uri, :purpose, :id, :type], @cast_opts)
    |> cast_embed(:styles, @cast_opts)
    |> validate_required([:id])
    |> validate_length(:text, min: 1)
    |> validate_length(:uri, min: 1)
    |> validate_inclusion(:type, [@resource_type])
    |> validate_uuid()
  end
end
