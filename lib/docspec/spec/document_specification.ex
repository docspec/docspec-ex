defmodule DocSpec.Spec.DocumentSpecification do
  @moduledoc """
  Ecto embedded schema for DocumentSpecification.

  ## Fields

  * `version` - Always `:alpha`.
  * `document` (required) - Allowed types: `DocSpec.Spec.Document`.
  """

  use DocSpec.Spec.Schema

  typed_embedded_schema null: false do
    field :version, Ecto.Enum, values: [:alpha], default: :alpha
    embeds_one :document, DocSpec.Spec.Document
  end

  @doc """
  Validates and casts the given attributes into a changeset.

  Ensures all required fields are present, embedded schemas are properly
  cast, and field values conform to their expected types and constraints.
  """
  def changeset(schema, attrs) do
    schema
    |> cast(attrs, [:version], @cast_opts)
    |> cast_embed(:document, @cast_opts ++ [required: true])
    |> validate_inclusion(:version, [:alpha])
  end
end
