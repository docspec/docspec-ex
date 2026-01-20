defmodule DocSpec.Core.BlockNote.Spec.Image do
  @moduledoc """
  BlockNote image block.
  """

  use DocSpec.Core.BlockNote.Spec

  @type props() :: %{:url => String.t(), :caption => String.t()}

  typedstruct enforce: true do
    field :id, String.t()
    field :type, :image, default: :image
    field :props, props()
  end
end
