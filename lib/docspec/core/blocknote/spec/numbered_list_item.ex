defmodule DocSpec.Core.BlockNote.Spec.NumberedListItem do
  @moduledoc """
  BlockNote numbered list item block.
  """

  use DocSpec.Core.BlockNote.Spec

  alias DocSpec.Core.BlockNote.Spec.BulletListItem

  @type content() :: DocSpec.Core.BlockNote.Spec.Text.t()
  @type props() :: %{optional(:start) => number()}

  typedstruct enforce: true do
    field :id, String.t()
    field :type, :numberedListItem, default: :numberedListItem
    field :content, [content()], default: []
    field :children, [__MODULE__.t() | BulletListItem.t()], default: []
    field :props, props(), default: %{}
  end
end
