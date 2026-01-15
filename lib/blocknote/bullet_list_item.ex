defmodule BlockNote.BulletListItem do
  @moduledoc """
  Represents a bullet list item with text content and nested children.
  """

  use TypedStruct

  @type content() :: BlockNote.Text.t()

  typedstruct enforce: true do
    field :id, String.t()
    field :type, :bulletListItem, default: :bulletListItem
    field :content, [content()], default: []
    field :children, [__MODULE__.t() | BlockNote.NumberedListItem.t()], default: []
  end
end
