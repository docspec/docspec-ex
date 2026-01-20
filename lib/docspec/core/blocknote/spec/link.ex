defmodule DocSpec.Core.BlockNote.Spec.Link do
  @moduledoc """
  BlockNote link inline content.
  """

  use DocSpec.Core.BlockNote.Spec

  @type content() :: DocSpec.Core.BlockNote.Spec.Text.t()

  typedstruct enforce: true do
    field :id, String.t()
    field :type, :link, default: :link
    field :content, [content()], default: []
    field :href, String.t()
  end
end
