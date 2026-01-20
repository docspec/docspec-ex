defmodule DocSpec.Spec.TableCell do
  @moduledoc """
  A data cell within a table row. Equivalent to HTML `<td>` element.

  ## Fields

  * `rowspan` - Represents the number of rows this table cell must span; this lets the cell occupy space across multiple rows of the table.
  * `colspan` - Represents the number of columns this table cell must span; this lets the cell occupy space across multiple columns of the table.
  * `children` (required) - Allowed types: `DocSpec.Spec.Paragraph`, `DocSpec.Spec.Heading`, `DocSpec.Spec.Image`, `DocSpec.Spec.Table`, `DocSpec.Spec.OrderedList`, `DocSpec.Spec.UnorderedList`, `DocSpec.Spec.BlockQuotation`, `DocSpec.Spec.DefinitionList`.
  * `id` (required)
  * `type` - Always `"https://alpha.docspec.io/TableCell"`.
  """

  use DocSpec.Spec.Schema, type: "https://alpha.docspec.io/TableCell"

  typed_embedded_schema null: false do
    # Represents the number of rows this table cell must span; this lets the cell occupy space across multiple rows
    # of the table.
    field :rowspan, :integer, default: 1

    # Represents the number of columns this table cell must span; this lets the cell occupy space across multiple
    # columns of the table.
    field :colspan, :integer, default: 1

    polymorphic_embeds_many :children,
      types: [
        "https://alpha.docspec.io/Paragraph": DocSpec.Spec.Paragraph,
        "https://alpha.docspec.io/Heading": DocSpec.Spec.Heading,
        "https://alpha.docspec.io/Image": DocSpec.Spec.Image,
        "https://alpha.docspec.io/Table": DocSpec.Spec.Table,
        "https://alpha.docspec.io/OrderedList": DocSpec.Spec.OrderedList,
        "https://alpha.docspec.io/UnorderedList": DocSpec.Spec.UnorderedList,
        "https://alpha.docspec.io/BlockQuotation": DocSpec.Spec.BlockQuotation,
        "https://alpha.docspec.io/DefinitionList": DocSpec.Spec.DefinitionList
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
    |> cast(attrs, [:rowspan, :colspan, :id, :type], @cast_opts)
    |> cast_polymorphic_embed(:children, @cast_opts ++ [required: true])
    |> validate_required([:id])
    |> validate_number(:rowspan, greater_than_or_equal_to: 1, less_than_or_equal_to: 66_534)
    |> validate_number(:colspan, greater_than_or_equal_to: 1, less_than_or_equal_to: 1000)
    |> validate_inclusion(:type, [@resource_type])
    |> validate_uuid()
  end
end
