defmodule DocSpec.Core.DOCX.Reader.AST.ParagraphProperties do
  @moduledoc """
  This module defines a struct that represents a `w:pPr` (paragraph properties) object in a Word document.

  See http://officeopenxml.com/WPparagraphProperties.php for more information on what a `w:pPr` object may contain.
  """

  alias DocSpec.Core.DOCX.Reader.AST.{NumberingProperties, ParagraphProperties}

  @type justification() :: :left | :right | :center | :both

  @type t :: %__MODULE__{
          num_properties: NumberingProperties.t() | nil,
          style_id: String.t() | nil,
          justification: justification() | nil
        }

  @fields [:num_properties, :style_id, :justification]
  @enforce_keys @fields
  defstruct @fields

  @spec parse(Saxy.XML.element() | nil) :: t()
  def parse(nil), do: %ParagraphProperties{style_id: nil, num_properties: nil, justification: nil}

  def parse({"w:pPr", _, children}) do
    style_id =
      children
      |> SimpleForm.Element.find_by_name("w:pStyle")
      |> SimpleForm.Attrs.get_value("w:val")

    num_properties =
      children |> SimpleForm.Element.find_by_name("w:numPr") |> NumberingProperties.parse()

    justification =
      children
      |> SimpleForm.Element.find_by_name("w:jc")
      |> SimpleForm.Attrs.get_value("w:val")
      |> parse_jc()

    %ParagraphProperties{
      style_id: style_id,
      num_properties: num_properties,
      justification: justification
    }
  end

  @spec parse_jc(term()) :: justification() | nil
  defp parse_jc(value) do
    case value do
      "left" -> :left
      "center" -> :center
      "right" -> :right
      "both" -> :both
      _ -> nil
    end
  end
end
