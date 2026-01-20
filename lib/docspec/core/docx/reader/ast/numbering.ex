defmodule DocSpec.Core.DOCX.Reader.AST.Numbering do
  @moduledoc """
  This module defines a struct that represents a numbering definition in a Word document
  as found in files like `word/numbering.xml`
  """

  alias DocSpec.Core.DOCX.Reader.AST.Numbering
  alias DocSpec.Spec.OrderedList
  alias DocSpec.Spec.UnorderedList

  @type t :: %__MODULE__{
          id: String.t(),
          level: integer() | nil,
          format: String.t() | nil,
          start: integer()
        }

  @fields [:id, :level, :format, :start]
  @enforce_keys @fields
  defstruct @fields

  @doc """
  Translates the `format` field of a numbering definition into a DocSpec style type for ordered or unordered lists.

  ## Examples

      iex> alias DocSpec.Core.DOCX.Reader.AST.Numbering
      iex> Numbering.style_type("decimal")
      "decimal"
      iex> Numbering.style_type("lowerLetter")
      "lower-alpha"
      iex> Numbering.style_type("disc")
      "disc"
      iex> Numbering.style_type(nil)
      "disc"
      iex> Numbering.style_type(%Numbering{id: "1", level: 1, format: "decimal", start: 3})
      "decimal"
  """
  @spec style_type(Numbering.t() | String.t() | nil) :: String.t()
  def style_type(%Numbering{format: format}), do: style_type(format)
  def style_type("decimal"), do: "decimal"
  def style_type("lowerLetter"), do: "lower-alpha"
  def style_type("upperLetter"), do: "upper-alpha"
  def style_type("lowerRoman"), do: "lower-roman"
  def style_type("upperRoman"), do: "upper-roman"
  def style_type(_), do: "disc"

  @doc """
  Converts a numbering definition into a DocSpec ordered or unordered list based on the style type as determined by the `format` field.

  ## Examples

      iex> alias DocSpec.Core.DOCX.Reader.AST.Numbering
      iex> alias DocSpec.Spec.{OrderedList, UnorderedList}
      iex> Numbering.to_list(%Numbering{id: "1", level: 1, format: "decimal", start: 3}) |> Map.put(:id, nil)
      %OrderedList{start: 3, style_type: "decimal", reversed: false}
      iex> Numbering.to_list(%Numbering{id: "2", level: 1, format: "lowerLetter", start: -1}) |> Map.put(:id, nil)
      %OrderedList{start: -1, style_type: "lower-alpha", reversed: false}
      iex> Numbering.to_list(%Numbering{id: "3", level: 1, format: "disc", start: 1}) |> Map.put(:id, nil)
      %UnorderedList{style_type: "disc"}
  """
  @spec to_list(Numbering.t()) :: OrderedList.t() | UnorderedList.t()
  def to_list(%Numbering{format: format, start: start}) do
    case style_type(format) do
      "disc" ->
        %UnorderedList{
          id: Ecto.UUID.generate(),
          style_type: "disc"
        }

      style_type ->
        %OrderedList{
          id: Ecto.UUID.generate(),
          start: start,
          style_type: style_type,
          reversed: false
        }
    end
  end
end
