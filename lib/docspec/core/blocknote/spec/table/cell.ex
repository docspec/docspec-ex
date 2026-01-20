defmodule DocSpec.Core.BlockNote.Spec.Table.Cell do
  @moduledoc """
  BlockNote table cell.
  """

  use DocSpec.Core.BlockNote.Spec

  alias DocSpec.Core.BlockNote.Spec.Text

  @type props() :: %{optional(:colspan) => integer(), optional(:rowspan) => integer()}

  typedstruct enforce: true do
    field :id, String.t()
    field :type, :tableCell, default: :tableCell
    field :content, [Text.t()], default: []
    field :props, props(), default: %{}
  end
end
