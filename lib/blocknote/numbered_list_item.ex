defmodule BlockNote.NumberedListItem do
  @moduledoc """
  Represents a numbered list item with text content and nested children.
  """

  use TypedStruct

  @type content() :: BlockNote.Text.t()

  @type props() :: %{optional(:start) => number()}

  typedstruct enforce: true do
    field :id, String.t()
    field :type, :numberedListItem, default: :numberedListItem
    field :content, [content()], default: []
    field :children, [__MODULE__.t() | BlockNote.BulletListItem.t()], default: []
    field :props, props(), default: %{}
  end
end
