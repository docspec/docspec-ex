defmodule DocSpec.Core.BlockNote.Spec.Table.Content do
  @moduledoc """
  BlockNote table content structure.
  """

  use DocSpec.Core.BlockNote.Spec

  @type row() :: %{cells: [DocSpec.Core.BlockNote.Spec.Table.Cell.t()]}

  typedstruct enforce: true do
    field :type, :tableContent, default: :tableContent
    field :rows, [row()], default: []
  end
end
