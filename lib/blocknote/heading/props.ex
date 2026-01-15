defmodule BlockNote.Heading.Props do
  @moduledoc """
  Properties for heading blocks including level and text alignment.
  """

  use TypedStruct

  typedstruct enforce: true do
    field :level, integer()
    field :text_alignment, String.t()
  end
end
