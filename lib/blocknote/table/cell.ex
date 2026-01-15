defmodule BlockNote.Table.Cell do
  @moduledoc """
  Represents a table cell with text content and optional colspan/rowspan.
  """

  use TypedStruct

  @type props() :: %{optional(:colspan) => integer(), optional(:rowspan) => integer()}

  typedstruct enforce: true do
    field :id, String.t()
    field :type, :tableCell, default: :tableCell
    field :content, [BlockNote.Text.t()], default: []
    field :props, props(), default: %{}
  end
end
