defmodule DocSpec.Core.BlockNote.Spec.Heading.Props do
  @moduledoc """
  BlockNote heading properties.
  """

  use DocSpec.Core.BlockNote.Spec

  typedstruct enforce: true do
    field :level, integer()
    field :text_alignment, String.t()
  end
end
