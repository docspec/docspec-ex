defmodule DocSpec.Core.BlockNote.Spec.Text.Styles do
  @moduledoc """
  BlockNote text styling options.
  """

  @type t :: %{
          optional(:bold) => boolean(),
          optional(:italic) => boolean(),
          optional(:underline) => boolean(),
          optional(:strike) => boolean(),
          optional(:text_color) => String.t(),
          optional(:background_color) => String.t()
        }
end
