defmodule BlockNote.Text do
  @moduledoc """
  Represents inline text content with optional styling.
  """

  use TypedStruct

  alias BlockNote.Text.Styles

  typedstruct enforce: true do
    field :type, :text, default: :text
    field :text, String.t()
    field :styles, Styles.t(), default: %{}
  end
end
