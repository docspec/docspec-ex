defmodule BlockNote.Heading do
  @moduledoc """
  Represents a heading block with configurable level and text alignment.
  """

  use TypedStruct

  alias BlockNote.Heading.Props

  @type content() :: BlockNote.Paragraph.content()

  typedstruct enforce: true do
    field :id, String.t()
    field :type, :heading, default: :heading
    field :content, [content()], default: []
    field :props, Props.t()
  end
end
