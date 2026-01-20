defmodule DocSpec.Core.DOCX.Reader.AST.Fonts.UTF8 do
  @moduledoc """
  This module translates characters in UTF-8 to UTF-8 characters.
  It's essentially a no-op.
  """
  alias DocSpec.Core.DOCX.Reader.AST.Fonts.FontBehaviour
  @behaviour FontBehaviour
  @impl FontBehaviour
  def to_utf8(string) when is_binary(string), do: string
  def to_utf8(codepoint) when is_integer(codepoint), do: <<codepoint::utf8>>
end
