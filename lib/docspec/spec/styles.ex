defmodule DocSpec.Spec.Styles do
  @moduledoc """
  Ecto embedded schema for Styles.

  ## Fields

  * `bold` - With strong importance, typically displayed in bold.
  * `italic` - With emphasis, typically displayed in italic.
  * `underline` - With an underline decoration.
  * `strikethrough` - With a horizontal line through the center, indicating deleted or no longer relevant content.
  * `superscript` - As superscript, displayed slightly above the normal line and in smaller font.
  * `subscript` - As subscript, displayed slightly below the normal line and in smaller font.
  * `code` - As inline code, typically displayed in a monospace font.
  * `mark` - As marked or highlighted, typically with a yellow background.
  * `text_color` - The foreground color of the text. Allowed types: `DocSpec.Spec.HexColor`.
  * `highlight_color` - The background/highlight color of the text. Allowed types: `DocSpec.Spec.HexColor`.
  """

  use DocSpec.Spec.Schema

  typed_embedded_schema null: false do
    # With strong importance, typically displayed in bold.
    field :bold, :boolean, default: false
    # With emphasis, typically displayed in italic.
    field :italic, :boolean, default: false
    # With an underline decoration.
    field :underline, :boolean, default: false
    # With a horizontal line through the center, indicating deleted or no longer relevant content.
    field :strikethrough, :boolean, default: false
    # As superscript, displayed slightly above the normal line and in smaller font.
    field :superscript, :boolean, default: false
    # As subscript, displayed slightly below the normal line and in smaller font.
    field :subscript, :boolean, default: false
    # As inline code, typically displayed in a monospace font.
    field :code, :boolean, default: false
    # As marked or highlighted, typically with a yellow background.
    field :mark, :boolean, default: false
    # The foreground color of the text.
    embeds_one :text_color, DocSpec.Spec.HexColor
    # The background/highlight color of the text.
    embeds_one :highlight_color, DocSpec.Spec.HexColor
  end

  @doc """
  Validates and casts the given attributes into a changeset.

  Ensures all required fields are present, embedded schemas are properly
  cast, and field values conform to their expected types and constraints.
  """
  def changeset(schema, attrs) do
    schema
    |> cast(
      attrs,
      [
        :bold,
        :italic,
        :underline,
        :strikethrough,
        :superscript,
        :subscript,
        :code,
        :mark
      ],
      @cast_opts
    )
    |> cast_embed(:text_color, @cast_opts)
    |> cast_embed(:highlight_color, @cast_opts)
  end
end
