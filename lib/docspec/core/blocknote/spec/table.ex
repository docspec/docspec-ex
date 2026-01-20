defmodule DocSpec.Core.BlockNote.Spec.Table do
  @moduledoc """
  BlockNote table block.
  """

  use DocSpec.Core.BlockNote.Spec

  @type content() :: DocSpec.Core.BlockNote.Spec.Table.Content.t()

  typedstruct enforce: true do
    field :id, String.t()
    field :type, :table, default: :table
    field :content, content()
  end
end
