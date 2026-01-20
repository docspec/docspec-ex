defmodule DocSpec.Spec.DocumentMeta do
  @moduledoc """
  Document metadata such as title, authors, and language.

  ## Fields

  * `title` - The document title.
  * `authors` - The document authors or creators. Allowed types: `DocSpec.Spec.Author`.
  * `description` - A brief description of the document.
  * `language` - The document language as a BCP 47 tag (e.g., 'en', 'nl-NL').
  """

  use DocSpec.Spec.Schema

  typed_embedded_schema null: false do
    # The document title.
    field :title, :string
    # The document authors or creators.
    embeds_many :authors, DocSpec.Spec.Author
    # A brief description of the document.
    field :description, :string
    # The document language as a BCP 47 tag (e.g., 'en', 'nl-NL').
    field :language, :string
  end

  @doc """
  Validates and casts the given attributes into a changeset.

  Ensures all required fields are present, embedded schemas are properly
  cast, and field values conform to their expected types and constraints.
  """
  def changeset(schema, attrs) do
    schema
    |> cast(attrs, [:title, :description, :language], @cast_opts)
    |> cast_embed(:authors, @cast_opts)
  end
end
