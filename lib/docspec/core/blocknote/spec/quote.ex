defmodule DocSpec.Core.BlockNote.Spec.Quote do
  @moduledoc """
  BlockNote quote block.

  See: https://www.blocknotejs.org/docs/features/blocks/typography#quote
  """

  use DocSpec.Core.BlockNote.Spec

  @type content() :: DocSpec.Core.BlockNote.Spec.Paragraph.content()
  @type props() :: %{optional(:text_alignment) => String.t()}

  typedstruct enforce: true do
    field :id, String.t()
    field :type, :quote, default: :quote
    field :content, [content()], default: []
    field :props, props(), default: %{}
  end
end
