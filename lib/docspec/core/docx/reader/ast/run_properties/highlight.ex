defmodule DocSpec.Core.DOCX.Reader.AST.RunProperties.Highlight do
  @moduledoc """
  Normalizes DOCX `w:highlight` values (ECMA-376 `ST_HighlightColor`) to an
  internal representation and exposes their RGB hex values.

  This module is responsible for:

    * Parsing raw `w:val` strings from run properties (e.g. `"yellow"`,
      `"darkBlue"`, `"none"`) to internal atoms via `t/0` using `parse/1`.
    * Converting those atoms to lowercase RGB hex strings (or `nil` for `:none`)
      via `to_hex/1`, for use in downstream rendering or style normalization.

  Invalid or unknown highlight values are mapped to `nil` by `parse/1`, allowing
  callers to treat them as “no highlight” or handle them explicitly upstream.
  """

  @type t() ::
          :none
          | :black
          | :blue
          | :cyan
          | :green
          | :magenta
          | :red
          | :yellow
          | :white
          | :dark_blue
          | :dark_cyan
          | :dark_green
          | :dark_magenta
          | :dark_red
          | :dark_yellow
          | :dark_gray
          | :light_gray

  @highlight_map %{
    "none" => :none,
    "black" => :black,
    "blue" => :blue,
    "cyan" => :cyan,
    "green" => :green,
    "magenta" => :magenta,
    "red" => :red,
    "yellow" => :yellow,
    "white" => :white,
    "darkBlue" => :dark_blue,
    "darkCyan" => :dark_cyan,
    "darkGreen" => :dark_green,
    "darkMagenta" => :dark_magenta,
    "darkRed" => :dark_red,
    "darkYellow" => :dark_yellow,
    "darkGray" => :dark_gray,
    "lightGray" => :light_gray
  }

  @doc """
  Parses an ST_HighlightColor string value to its internal atom representation.

  ## Examples

      iex> alias DocSpec.Core.DOCX.Reader.AST.RunProperties.Highlight
      iex> Highlight.parse("yellow")
      :yellow
      iex> Highlight.parse("not-a-color")
      nil
  """
  @spec parse(color :: term()) :: t() | nil
  def parse(color) when is_binary(color),
    do: Map.get(@highlight_map, color)

  def parse(_),
    do: nil

  @doc """
  Returns the lowercase hex RGB value for a highlight atom, or `nil` for `:none`.

  ## Examples

      iex> alias DocSpec.Core.DOCX.Reader.AST.RunProperties.Highlight
      iex> Highlight.to_hex(:none)
      nil
      iex> Highlight.to_hex(:black)
      "#000000"
      iex> Highlight.to_hex(:blue)
      "#0000ff"
      iex> Highlight.to_hex(:cyan)
      "#00ffff"
      iex> Highlight.to_hex(:green)
      "#00ff00"
      iex> Highlight.to_hex(:magenta)
      "#ff00ff"
      iex> Highlight.to_hex(:red)
      "#ff0000"
      iex> Highlight.to_hex(:yellow)
      "#ffff00"
      iex> Highlight.to_hex(:white)
      "#ffffff"
      iex> Highlight.to_hex(:dark_blue)
      "#000080"
      iex> Highlight.to_hex(:dark_cyan)
      "#008080"
      iex> Highlight.to_hex(:dark_green)
      "#008000"
      iex> Highlight.to_hex(:dark_magenta)
      "#800080"
      iex> Highlight.to_hex(:dark_red)
      "#800000"
      iex> Highlight.to_hex(:dark_yellow)
      "#808000"
      iex> Highlight.to_hex(:dark_gray)
      "#808080"
      iex> Highlight.to_hex(:light_gray)
      "#c0c0c0"
  """
  @spec to_hex(highlight :: t() | nil) :: String.t() | nil
  def to_hex(nil), do: nil
  def to_hex(:none), do: nil
  def to_hex(:black), do: "#000000"
  def to_hex(:blue), do: "#0000ff"
  def to_hex(:cyan), do: "#00ffff"
  def to_hex(:green), do: "#00ff00"
  def to_hex(:magenta), do: "#ff00ff"
  def to_hex(:red), do: "#ff0000"
  def to_hex(:yellow), do: "#ffff00"
  def to_hex(:white), do: "#ffffff"
  def to_hex(:dark_blue), do: "#000080"
  def to_hex(:dark_cyan), do: "#008080"
  def to_hex(:dark_green), do: "#008000"
  def to_hex(:dark_magenta), do: "#800080"
  def to_hex(:dark_red), do: "#800000"
  def to_hex(:dark_yellow), do: "#808000"
  def to_hex(:dark_gray), do: "#808080"
  def to_hex(:light_gray), do: "#c0c0c0"
end
