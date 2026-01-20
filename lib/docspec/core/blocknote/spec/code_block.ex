defmodule DocSpec.Core.BlockNote.Spec.CodeBlock do
  @moduledoc """
  BlockNote code block.

  See: https://www.blocknotejs.org/docs/features/blocks/code-blocks
  """

  use DocSpec.Core.BlockNote.Spec

  @type content() :: DocSpec.Core.BlockNote.Spec.Paragraph.content()
  @type props() :: %{optional(:text_alignment) => String.t()}

  typedstruct enforce: true do
    field :id, String.t()
    field :type, :codeBlock, default: :codeBlock
    field :content, [content()], default: []
    field :props, props(), default: %{}
  end
end
