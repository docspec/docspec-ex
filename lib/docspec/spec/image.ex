defmodule DocSpec.Spec.Image do
  @moduledoc """
  An embedded image referencing an asset or external URI. Equivalent to HTML `<img>` element.

  ## Fields

  * `source` (required) - The source of the image, either an asset reference or external URI. Allowed types: `DocSpec.Spec.AssetSource`, `DocSpec.Spec.UriSource`.
  * `caption` - A caption providing the image an accessible description. Allowed types: `DocSpec.Spec.Paragraph`.
  * `alternative_text` - The alt text of the image. Non-discernible text is considered not set.
  * `decorative` - Specifies if an image is decorative or functional.
  * `id` (required)
  * `type` - Always `"https://alpha.docspec.io/Image"`.
  """

  use DocSpec.Spec.Schema, type: "https://alpha.docspec.io/Image"

  typed_embedded_schema null: false do
    # The source of the image, either an asset reference or external URI.
    polymorphic_embeds_one :source,
      types: [
        asset_source: [module: DocSpec.Spec.AssetSource, identify_by_fields: [:asset_id]],
        uri_source: [module: DocSpec.Spec.UriSource, identify_by_fields: [:uri]]
      ],
      on_replace: :update

    # A caption providing the image an accessible description.
    embeds_many :caption, DocSpec.Spec.Paragraph
    # The alt text of the image. Non-discernible text is considered not set.
    field :alternative_text, :string
    # Specifies if an image is decorative or functional.
    field :decorative, :boolean, default: false
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
    |> cast(attrs, [:alternative_text, :decorative, :id, :type], @cast_opts)
    |> cast_polymorphic_embed(:source, @cast_opts ++ [required: true])
    |> cast_embed(:caption, @cast_opts)
    |> validate_required([:id])
    |> validate_inclusion(:type, [@resource_type])
    |> validate_uuid()
  end
end
