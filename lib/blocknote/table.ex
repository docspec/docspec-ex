defmodule BlockNote.Table do
  @moduledoc """
  Represents a table block containing rows and cells.
  """

  use TypedStruct

  @type content() :: BlockNote.Table.Content.t()

  typedstruct enforce: true do
    field :id, String.t()
    field :type, :table, default: :table
    field :content, content()
  end
end
