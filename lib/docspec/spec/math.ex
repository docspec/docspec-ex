defmodule DocSpec.Spec.Math do
  @moduledoc """
  Inline mathematical notation using LaTeX syntax. Rendered within text flow.

  ## Fields

  * `content` (required) - LaTeX math notation without delimiters (e.g., 'E = mc^2', '\frac{a}{b}').
  * `id` (required)
  * `type` - Always `"https://alpha.docspec.io/Math"`.
  """

  use DocSpec.Spec.Schema, type: "https://alpha.docspec.io/Math"

  typed_embedded_schema null: false do
    # LaTeX math notation without delimiters (e.g., 'E = mc^2', '\frac{a}{b}').
    field :content, :string
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
    |> cast(attrs, [:content, :id, :type], @cast_opts)
    |> validate_required([:id])
    |> validate_length(:content, min: 1)
    |> validate_inclusion(:type, [@resource_type])
    |> validate_uuid()
  end
end
