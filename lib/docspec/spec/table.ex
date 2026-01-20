defmodule DocSpec.Spec.Table do
  @moduledoc """
  A table structure containing rows. Equivalent to HTML `<table>` element.

  ## Fields

  * `caption` - A caption providing the table an accessible description. Allowed types: `DocSpec.Spec.Paragraph`.
  * `children` (required) - Allowed types: `DocSpec.Spec.TableRow`.
  * `id` (required)
  * `type` - Always `"https://alpha.docspec.io/Table"`.
  """

  use DocSpec.Spec.Schema, type: "https://alpha.docspec.io/Table"

  typed_embedded_schema null: false do
    # A caption providing the table an accessible description.
    embeds_many :caption, DocSpec.Spec.Paragraph
    embeds_many :children, DocSpec.Spec.TableRow
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
    |> cast_embed(:children, @cast_opts ++ [required: true])
    |> validate_required([:id])
    |> validate_inclusion(:type, [@resource_type])
    |> validate_uuid()
  end
end
