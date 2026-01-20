defmodule DocSpec.Core.EPUB.Writer.TableOfContents do
  @moduledoc """
  Generates table of contents navigation files for EPUBs.

  This module creates both EPUB 3 (XHTML nav) and EPUB 2 (NCX) navigation
  documents. Including both formats ensures maximum compatibility across
  different EPUB readers:

  - XHTML nav (`nav.xhtml`) - EPUB 3 standard navigation
  - NCX (`toc.ncx`) - EPUB 2 legacy navigation for backward compatibility

  Both navigation files provide the same structure but in different formats
  required by the respective EPUB specifications.
  """

  alias DocSpec.Core.EPUB.Writer.XHTML
  alias DocSpec.Spec.Document

  @type ncx() :: Saxy.XML.element()

  @doc """
  Creates an XHTML navigation document for EPUB 3.

  Generates the `OEBPS/text/nav.xhtml` file containing a table of contents
  in XHTML format. This is the standard navigation format for EPUB 3.

  ## Returns

  A Saxy XML element representing the complete XHTML navigation document.

  ## Examples

      iex> alias DocSpec.Core.EPUB.Writer.TableOfContents
      iex> {"html", _attrs, _children} = TableOfContents.create_xhtml()

  """
  @spec create_xhtml() :: XHTML.t()
  def create_xhtml do
    XHTML.Element.html([
      XHTML.Element.head([]),
      XHTML.Element.body(
        [
          {"h1", [], ["Table of Contents"]},
          {
            "ol",
            [],
            [
              {"li", [],
               [
                 {"a", [{"href", "document.xhtml"}], ["Document"]}
               ]}
            ]
          }
        ],
        :nav
      )
    ])
  end

  @doc """
  Creates an NCX navigation document for EPUB 2 compatibility.

  Generates the `OEBPS/toc.ncx` file containing a table of contents in NCX
  (Navigation Control file for XML) format. This provides backward
  compatibility with EPUB 2 readers.

  ## Parameters

  - `doc` - The DocSpec document (used to extract metadata like ID)

  ## Returns

  A Saxy XML element representing the NCX navigation document.

  ## Examples

      iex> alias DocSpec.Core.EPUB.Writer.TableOfContents
      iex> alias DocSpec.Spec.Document
      iex> doc = %Document{id: "abc-123", children: []}
      iex> {"ncx", _attrs, _children} = TableOfContents.create_ncx(doc)

  """
  @spec create_ncx(doc :: Document.t()) :: ncx()
  def create_ncx(doc = %Document{}) do
    {
      "ncx",
      [
        {"xmlns", "http://www.daisy.org/z3986/2005/ncx/"},
        {"version", "2005-1"}
      ],
      [
        {
          "head",
          [],
          [
            {
              "meta",
              [
                {"name", "dtb:uid"},
                {"content", doc.id}
              ],
              []
            }
          ]
        },
        {"docTitle", [], [{"text", [], ["Placeholder"]}]},
        {
          "navMap",
          [],
          [
            {
              "navPoint",
              [{"id", "doc"}, {"playOrder", "1"}],
              [
                {"navLabel", [], [{"text", [], ["Document"]}]},
                {"content", [{"src", "text/document.xhtml"}], []}
              ]
            }
          ]
        }
      ]
    }
  end
end
