defmodule DocSpec.Core.BlockNote.Spec.Text do
  @moduledoc """
  BlockNote text inline content.
  """

  use DocSpec.Core.BlockNote.Spec

  alias DocSpec.Core.BlockNote.Spec.Text.Styles

  typedstruct enforce: true do
    field :type, :text, default: :text
    field :text, String.t()
    field :styles, Styles.t(), default: %{}
  end
end
