defmodule DocSpec.Core.DOCX.Reader.AST.Fonts.FontBehaviour do
  @moduledoc """
  This module defines the behaviour of a font module.
  """
  @callback to_utf8(String.t()) :: String.t()
  @callback to_utf8(integer()) :: String.t() | nil
end
