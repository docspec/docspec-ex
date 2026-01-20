defmodule DocSpec.Core.BlockNote.Spec.Document do
  @moduledoc """
  BlockNote document structure.
  """

  use DocSpec.Core.BlockNote.Spec

  @type content() ::
          DocSpec.Core.BlockNote.Spec.BulletListItem.t()
          | DocSpec.Core.BlockNote.Spec.CodeBlock.t()
          | DocSpec.Core.BlockNote.Spec.Heading.t()
          | DocSpec.Core.BlockNote.Spec.Image.t()
          | DocSpec.Core.BlockNote.Spec.NumberedListItem.t()
          | DocSpec.Core.BlockNote.Spec.Paragraph.t()
          | DocSpec.Core.BlockNote.Spec.Quote.t()
          | DocSpec.Core.BlockNote.Spec.Table.t()

  typedstruct enforce: true do
    field :id, String.t()
    field :content, [content()], default: []
  end
end
