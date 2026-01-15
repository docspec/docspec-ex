defmodule BlockNote.Text.Styles do
  @moduledoc """
  Defines text styling options including bold, italic, and colors.
  """

  @type t :: %{
          optional(:bold) => boolean(),
          optional(:italic) => boolean(),
          optional(:text_color) => String.t(),
          optional(:background_color) => String.t()
        }
end
