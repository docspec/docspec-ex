defmodule DocSpec.Core.EPUB.Writer.Chapter do
  @moduledoc """
  Converts DocSpec documents into EPUB chapter XHTML content.

  This module handles the conversion of document content into the XHTML format
  required for EPUB chapters, which are stored as `OEBPS/text/document.xhtml`
  files inside an EPUB archive.
  """

  alias DocSpec.Core.EPUB.Writer, as: EPUB
  alias DocSpec.Core.HTML.Writer, as: HTML
  alias DocSpec.Spec.Document

  @doc """
  Converts a document into an XHTML chapter for EPUB.

  Takes a document and converts its children to XHTML suitable for an EPUB
  chapter. The output is a complete HTML document with proper structure
  including head and body elements.

  ## Examples

      iex> alias DocSpec.Core.EPUB.Writer.Chapter
      iex> alias DocSpec.Spec.{Document, Paragraph, Text}
      iex> doc = %Document{id: "test", children: [%Paragraph{children: [%Text{text: "Hello"}]}]}
      iex> Chapter.convert(doc)
      {"html",
        [
          {"xmlns", "http://www.w3.org/1999/xhtml"},
          {"xmlns:epub", "http://www.idpf.org/2007/ops"}
        ],
        [
          {"head", [], [
            {"link", [{"rel", "stylesheet"}, {"type", "text/css"}, {"href", "../css/style.css"}], []},
            {"title", [], ["Document"]}
          ]},
          {"body", [], [
            {"section", [{"epub:type", "chapter"}], [
              {"p", [], ["Hello"]}
            ]}
          ]}
        ]
      }

  """
  @spec convert(doc :: Document.t()) :: EPUB.XHTML.t()
  def convert(document = %Document{}) do
    EPUB.XHTML.Element.html([
      EPUB.XHTML.Element.head([]),
      document
      |> HTML.convert_to_simple_form(fn_asset_to_uri: &EPUB.Asset.path(&1, :from_doc))
      |> get_body_children()
      |> EPUB.XHTML.from_html()
      |> EPUB.XHTML.Element.body(:chapter)
    ])
  end

  @spec get_body_children(node :: Floki.html_node()) :: [Floki.html_node()]

  defp get_body_children({"html", _, children}) do
    body = Enum.find(children, &match?({"body", _, _}, &1))

    if body do
      {"body", _, children} = body
      children
    else
      []
    end
  end
end
