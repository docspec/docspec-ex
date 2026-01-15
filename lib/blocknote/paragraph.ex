defmodule BlockNote.Paragraph do
  @moduledoc """
  Represents a paragraph block containing text and link content.
  """

  use TypedStruct

  @type content() :: BlockNote.Text.t() | BlockNote.Link.t()
  @type props() :: %{optional(:text_alignment) => String.t()}

  typedstruct enforce: true do
    field :id, String.t()
    field :type, :paragraph, default: :paragraph
    field :content, [content()], default: []
    field :props, props(), default: %{}
  end
end
