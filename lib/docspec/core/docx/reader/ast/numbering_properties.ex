defmodule DocSpec.Core.DOCX.Reader.AST.NumberingProperties do
  @moduledoc """
  This module defines a struct that represents a `w:numPr` (numbering properties) object in a Word document.

  See http://officeopenxml.com/WPparagraphProperties.php, element `numPr` for more information on what a
  `w:numPr` object may contain.
  """

  alias DocSpec.Core.DOCX.Reader.AST.NumberingProperties

  @type t :: %__MODULE__{
          num_id: String.t(),
          ilvl: integer()
        }

  @fields [:num_id, :ilvl]
  @enforce_keys @fields
  defstruct @fields

  @spec parse(nil) :: nil
  def parse(nil), do: nil

  @spec parse(Saxy.XML.element()) :: t()
  def parse({"w:numPr", _, children}) do
    num_id =
      children
      |> SimpleForm.Element.find_by_name("w:numId")
      |> SimpleForm.Attrs.get_value("w:val", "1")

    ilvl =
      children
      |> SimpleForm.Element.find_by_name("w:ilvl")
      |> SimpleForm.Attrs.get_value("w:val", "0")
      |> String.to_integer()

    %NumberingProperties{num_id: num_id, ilvl: ilvl}
  end
end
