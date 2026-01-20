defmodule DocSpec.Core.DOCX.Reader.AST.Style do
  @moduledoc """
  This module defines a struct that represents a style in a Word document.
  """
  alias DocSpec.Core.DOCX.Reader.AST.Style

  @type t :: %__MODULE__{
          id: String.t(),
          type: style_type(),
          name: String.t(),
          based_on: String.t() | nil
        }

  @type style_type ::
          :title
          | :heading
          | :paragraph
          | :blockquote
          | :inline_quote
          | :code
          | :definition_term
          | :definition

  @fields [:id, :type, :name, :based_on]
  @enforce_keys @fields
  defstruct @fields

  # coveralls-ignore-start Guard functions cannot be covered by ExCoveralls

  defguard is_code(style) when not is_nil(style) and style.type == :code
  defguard is_title(style) when not is_nil(style) and style.type == :title
  defguard is_heading(style) when not is_nil(style) and style.type == :heading
  defguard is_paragraph(style) when not is_nil(style) and style.type == :paragraph
  defguard is_blockquote(style) when not is_nil(style) and style.type == :blockquote
  defguard is_inline_quote(style) when not is_nil(style) and style.type == :inline_quote
  defguard is_definition_term(style) when not is_nil(style) and style.type == :definition_term
  defguard is_definition(style) when not is_nil(style) and style.type == :definition

  # coveralls-ignore-stop

  @doc """
  Get the heading level of a heading style from its name (case-insensitive)
  The style must have type `:heading`.

  ## Examples

      iex> alias DocSpec.Core.DOCX.Reader.AST.Style
      iex> Style.heading_level(%Style{id: "test", based_on: nil, type: :heading, name: "heading 1"})
      1
      iex> Style.heading_level(%Style{id: "test", based_on: nil, type: :heading, name: "heading 2"})
      2
      iex> Style.heading_level(%Style{id: "test", based_on: nil, type: :heading, name: "HeAdInG 3"})
      3
      iex> Style.heading_level(%Style{id: "test", based_on: nil, type: :paragraph, name: "heading 1"})
      nil
  """
  @spec heading_level(Style.t()) :: integer() | nil
  def heading_level(%Style{type: :heading, name: name}) do
    case Regex.named_captures(~r/^heading (?<level>\d+)$/i, name)["level"] do
      nil -> nil
      level -> String.to_integer(level)
    end
  end

  def heading_level(_), do: nil
end
