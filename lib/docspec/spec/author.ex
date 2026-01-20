defmodule DocSpec.Spec.Author do
  @moduledoc """
  A document author or contributor.

  ## Fields

  * `name` (required) - The author's full name.
  * `email` - The author's email address.
  * `phone` - The author's phone number.
  * `website` - The author's website URL.
  """

  use DocSpec.Spec.Schema

  typed_embedded_schema null: false do
    # The author's full name.
    field :name, :string
    # The author's email address.
    field :email, :string
    # The author's phone number.
    field :phone, :string
    # The author's website URL.
    field :website, :string
  end

  @doc """
  Validates and casts the given attributes into a changeset.

  Ensures all required fields are present, embedded schemas are properly
  cast, and field values conform to their expected types and constraints.
  """
  def changeset(schema, attrs) do
    schema
    |> cast(attrs, [:name, :email, :phone, :website], @cast_opts)
    |> validate_length(:name, min: 1)
  end
end
