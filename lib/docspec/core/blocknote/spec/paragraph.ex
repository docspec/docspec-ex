defmodule DocSpec.Core.BlockNote.Spec.Paragraph do
  @moduledoc """
  BlockNote paragraph block.
  """

  use DocSpec.Core.BlockNote.Spec

  @type content() :: DocSpec.Core.BlockNote.Spec.Text.t() | DocSpec.Core.BlockNote.Spec.Link.t()
  @type props() :: %{optional(:text_alignment) => String.t()}

  typedstruct enforce: true do
    field :id, String.t()
    field :type, :paragraph, default: :paragraph
    field :content, [content()], default: []
    field :props, props(), default: %{}
  end
end
