defmodule DocSpec.Spec.Preformatted do
  @moduledoc """
  Preformatted text where whitespace is preserved. Equivalent to HTML `<pre>` element.

  ## Fields

  * `caption` - A caption providing the preformatted block an accessible description. Allowed types: `DocSpec.Spec.Paragraph`.
  * `children` (required) - Allowed types: `DocSpec.Spec.Text`, `DocSpec.Spec.Link`, `DocSpec.Spec.Image`, `DocSpec.Spec.FootnoteReference`, `DocSpec.Spec.Math`.
  * `id` (required)
  * `type` - Always `"https://alpha.docspec.io/Preformatted"`.
  """

  use DocSpec.Spec.Schema, type: "https://alpha.docspec.io/Preformatted"

  typed_embedded_schema null: false do
    # A caption providing the preformatted block an accessible description.
    embeds_many :caption, DocSpec.Spec.Paragraph

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
    |> cast(attrs, [:id, :type], @cast_opts)
    |> cast_embed(:caption, @cast_opts)
    |> cast_polymorphic_embed(:children, @cast_opts ++ [required: true])
    |> validate_required([:id])
    |> validate_inclusion(:type, [@resource_type])
    |> validate_uuid()
  end
end
