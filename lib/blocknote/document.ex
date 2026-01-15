defmodule BlockNote.Document do
  @moduledoc """
  Represents a BlockNote document containing a list of block-level content.
  """

  use TypedStruct

  @type content() ::
          BlockNote.BulletListItem.t()
          | BlockNote.CodeBlock.t()
          | BlockNote.Heading.t()
          | BlockNote.Image.t()
          | BlockNote.NumberedListItem.t()
          | BlockNote.Paragraph.t()
          | BlockNote.Quote.t()
          | BlockNote.Table.t()

  typedstruct enforce: true do
    field :id, String.t()
    field :content, [content()], default: []
  end
end
