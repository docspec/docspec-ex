defmodule DocSpec.Spec.Heading do
  @moduledoc """
  A section heading. Equivalent to HTML `<h1>` through `<h6>` elements.

  ## Fields

  * `level` (required) - The heading level. While HTML only supports levels 1-6, some formats such as OOXML support deeper nesting.
  * `children` (required) - Allowed types: `DocSpec.Spec.Text`, `DocSpec.Spec.Link`, `DocSpec.Spec.Image`, `DocSpec.Spec.FootnoteReference`, `DocSpec.Spec.Math`.
  * `id` (required)
  * `type` - Always `"https://alpha.docspec.io/Heading"`.
  """

  use DocSpec.Spec.Schema, type: "https://alpha.docspec.io/Heading"

  typed_embedded_schema null: false do
    # The heading level. While HTML only supports levels 1-6, some formats such as OOXML support deeper nesting.
    field :level, :integer

    polymorphic_embeds_many :children,
      types: [
        "https://alpha.docspec.io/Text": DocSpec.Spec.Text,
        "https://alpha.docspec.io/Link": DocSpec.Spec.Link,
        "https://alpha.docspec.io/Image": DocSpec.Spec.Image,
        "https://alpha.docspec.io/FootnoteReference": DocSpec.Spec.FootnoteReference,
        "https://alpha.docspec.io/Math": DocSpec.Spec.Math
      ],
      type_field_name: :type,
      on_replace: :delete

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
    |> cast(attrs, [:level, :id, :type], @cast_opts)
    |> cast_polymorphic_embed(:children, @cast_opts ++ [required: true])
    |> validate_required([:level, :id])
    |> validate_number(:level, greater_than_or_equal_to: 1)
    |> validate_inclusion(:type, [@resource_type])
    |> validate_uuid()
  end
end
