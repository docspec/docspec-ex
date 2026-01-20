defmodule DocSpec.Spec.TableRow do
  @moduledoc """
  A row within a table. Equivalent to HTML `<tr>` element.

  ## Fields

  * `children` (required) - Allowed types: `DocSpec.Spec.TableCell`, `DocSpec.Spec.TableHeader`.
  * `id` (required)
  * `type` - Always `"https://alpha.docspec.io/TableRow"`.
  """

  use DocSpec.Spec.Schema, type: "https://alpha.docspec.io/TableRow"

  typed_embedded_schema null: false do
    polymorphic_embeds_many :children,
      types: [
        "https://alpha.docspec.io/TableCell": DocSpec.Spec.TableCell,
        "https://alpha.docspec.io/TableHeader": DocSpec.Spec.TableHeader
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
    |> cast_polymorphic_embed(:children, @cast_opts ++ [required: true])
    |> validate_required([:id])
    |> validate_inclusion(:type, [@resource_type])
    |> validate_uuid()
  end
end
