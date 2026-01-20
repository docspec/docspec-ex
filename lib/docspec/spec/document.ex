defmodule DocSpec.Spec.Document do
  @moduledoc """
  The root document container. Holds all content blocks and embedded assets.

  ## Fields

  * `cite` - A URI that designates a source document or message for the information.
  * `metadata` - Document metadata such as title, authors, and language. Allowed types: `DocSpec.Spec.DocumentMeta`.
  * `footnotes` - Footnotes referenced within the document. Allowed types: `DocSpec.Spec.Footnote`.
  * `assets` - Embedded assets such as images, fonts, or other binary data referenced within the document. Allowed types: `DocSpec.Spec.Asset`.
  * `children` (required) - Allowed types: `DocSpec.Spec.Paragraph`, `DocSpec.Spec.Heading`, `DocSpec.Spec.Image`, `DocSpec.Spec.Table`, `DocSpec.Spec.OrderedList`, `DocSpec.Spec.UnorderedList`, `DocSpec.Spec.BlockQuotation`, `DocSpec.Spec.DefinitionList`, `DocSpec.Spec.ThematicBreak`, `DocSpec.Spec.Preformatted`.
  * `id` (required)
  * `type` - Always `"https://alpha.docspec.io/Document"`.
  """

  use DocSpec.Spec.Schema, type: "https://alpha.docspec.io/Document"

  typed_embedded_schema null: false do
    # A URI that designates a source document or message for the information.
    field :cite, :string
    # Document metadata such as title, authors, and language.
    embeds_one :metadata, DocSpec.Spec.DocumentMeta
    # Footnotes referenced within the document.
    embeds_many :footnotes, DocSpec.Spec.Footnote
    # Embedded assets such as images, fonts, or other binary data referenced within the document.
    embeds_many :assets, DocSpec.Spec.Asset

    polymorphic_embeds_many :children,
      types: [
        "https://alpha.docspec.io/Paragraph": DocSpec.Spec.Paragraph,
        "https://alpha.docspec.io/Heading": DocSpec.Spec.Heading,
        "https://alpha.docspec.io/Image": DocSpec.Spec.Image,
        "https://alpha.docspec.io/Table": DocSpec.Spec.Table,
        "https://alpha.docspec.io/OrderedList": DocSpec.Spec.OrderedList,
        "https://alpha.docspec.io/UnorderedList": DocSpec.Spec.UnorderedList,
        "https://alpha.docspec.io/BlockQuotation": DocSpec.Spec.BlockQuotation,
        "https://alpha.docspec.io/DefinitionList": DocSpec.Spec.DefinitionList,
        "https://alpha.docspec.io/ThematicBreak": DocSpec.Spec.ThematicBreak,
        "https://alpha.docspec.io/Preformatted": DocSpec.Spec.Preformatted
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
    |> cast(attrs, [:cite, :id, :type], @cast_opts)
    |> cast_embed(:metadata, @cast_opts)
    |> cast_embed(:footnotes, @cast_opts)
    |> cast_embed(:assets, @cast_opts)
    |> cast_polymorphic_embed(:children, @cast_opts ++ [required: true])
    |> validate_required([:id])
    |> validate_inclusion(:type, [@resource_type])
    |> validate_uuid()
  end
end
