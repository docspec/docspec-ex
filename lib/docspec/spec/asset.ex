defmodule DocSpec.Spec.Asset do
  @moduledoc """
  Data included in document, such as an image or attachment.

  ## Fields

  * `data` (required) - The asset data, either as a raw string or encoded according to the encoding property.
  * `content_type` (required) - The MIME type of the asset (e.g., 'image/png', 'font/woff2').
  * `encoding` - Always `"base64"`.
  * `id` (required)
  * `type` - Always `"https://alpha.docspec.io/Asset"`.
  """

  use DocSpec.Spec.Schema, type: "https://alpha.docspec.io/Asset"

  typed_embedded_schema null: false do
    # The asset data, either as a raw string or encoded according to the encoding property.
    field :data, :string
    # The MIME type of the asset (e.g., 'image/png', 'font/woff2').
    field :content_type, :string

    # The encoding used for the data property. When set to 'base64', the data is base64-encoded. When omitted, the
    # data is a raw string (useful for text-based formats like SVG).
    field :encoding, :string, default: "base64"
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
    |> cast(attrs, [:data, :content_type, :encoding, :id, :type], @cast_opts)
    |> validate_required([:id])
    |> validate_length(:data, min: 1)
    |> validate_length(:content_type, min: 1)
    |> validate_inclusion(:encoding, ["base64"])
    |> validate_inclusion(:type, [@resource_type])
    |> validate_uuid()
  end
end
