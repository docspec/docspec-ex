defmodule BlockNote.Table.Content do
  @moduledoc """
  Represents the content structure of a table containing rows.
  """

  use TypedStruct

  @type row() :: %{cells: [BlockNote.Table.Cell.t()]}

  typedstruct enforce: true do
    field :type, :tableContent, default: :tableContent
    field :rows, [row()], default: []
  end
end
