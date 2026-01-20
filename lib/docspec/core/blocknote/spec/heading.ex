defmodule DocSpec.Core.BlockNote.Spec.Heading do
  @moduledoc """
  BlockNote heading block.
  """

  use DocSpec.Core.BlockNote.Spec

  alias DocSpec.Core.BlockNote.Spec.Heading.Props

  @type content() :: DocSpec.Core.BlockNote.Spec.Paragraph.content()

  typedstruct enforce: true do
    field :id, String.t()
    field :type, :heading, default: :heading
    field :content, [content()], default: []
    field :props, Props.t()
  end
end
