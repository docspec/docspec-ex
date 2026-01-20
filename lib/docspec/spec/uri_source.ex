defmodule DocSpec.Spec.UriSource do
  @moduledoc """
  A reference to an external resource by URI.

  ## Fields

  * `uri` (required) - The URI of the external resource.
  """

  use DocSpec.Spec.Schema

  typed_embedded_schema null: false do
    # The URI of the external resource.
    field :uri, :string
  end

  @doc """
  Validates and casts the given attributes into a changeset.

  Ensures all required fields are present, embedded schemas are properly
  cast, and field values conform to their expected types and constraints.
  """
  def changeset(schema, attrs) do
    schema
    |> cast(attrs, [:uri], @cast_opts)
    |> validate_length(:uri, min: 1)
  end
end
