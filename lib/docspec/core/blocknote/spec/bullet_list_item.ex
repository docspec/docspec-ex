defmodule DocSpec.Core.BlockNote.Spec.BulletListItem do
  @moduledoc """
  BlockNote bullet list item block.
  """

  use DocSpec.Core.BlockNote.Spec

  alias DocSpec.Core.BlockNote.Spec.NumberedListItem

  @type content() :: DocSpec.Core.BlockNote.Spec.Text.t()

  typedstruct enforce: true do
    field :id, String.t()
    field :type, :bulletListItem, default: :bulletListItem
    field :content, [content()], default: []
    field :children, [__MODULE__.t() | NumberedListItem.t()], default: []
  end
end
