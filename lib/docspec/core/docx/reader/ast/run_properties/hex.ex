defmodule DocSpec.Core.DOCX.Reader.AST.RunProperties.Hex do
  @moduledoc """
  Normalizes and validates hexadecimal color values found in DOCX run properties.

  Accepts bare hexadecimal color strings (e.g. `"FF0000"` or `"fff"`) and,
  if valid, normalizes them to CSS-style color strings by prefixing a `#`.
  """

  @color_regex ~r/^(?:[0-9A-Fa-f]{3}|[0-9A-Fa-f]{6})$/

  @type t() :: String.t()

  @doc """
  Parses a DOCX hex color value and returns a CSS-style `#RRGGBB` or `#RGB` string.

  The input must be a 3- or 6-character hexadecimal string (case-insensitive)
  **without** a leading `#`. Any invalid value or non-binary term returns `nil`.

  Any black color will be ignored, as that is the default color.

  ## Examples

      iex> alias DocSpec.Core.DOCX.Reader.AST.RunProperties.Hex
      iex> Hex.parse("fff")
      "#fff"
      iex> Hex.parse("FF0000")
      "#FF0000"
      iex> Hex.parse("00ff7A")
      "#00ff7A"
      iex> Hex.parse("ffff")
      nil
      iex> Hex.parse("xyz")
      nil
      iex> Hex.parse(nil)
      nil
  """
  def parse(color) when is_binary(color) do
    if String.match?(color, @color_regex) do
      "#" <> color
    else
      nil
    end
  end

  def parse(_),
    do: nil
end
