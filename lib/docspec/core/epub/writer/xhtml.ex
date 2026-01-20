defmodule DocSpec.Core.EPUB.Writer.XHTML do
  @moduledoc """
  Converts Floki HTML nodes to Saxy XML elements for EPUB generation.
  """

  @type t() :: Saxy.XML.element()

  @doc """
  Converts Floki HTML nodes to Saxy XML elements.

  Images and HTML comments are filtered out. Images require special handling
  in EPUB manifests, and comments are not needed in the output.

  ## Examples

      iex> alias DocSpec.Core.EPUB.Writer.XHTML
      iex> XHTML.from_html({"p", [], ["Hello"]})
      {"p", [], ["Hello"]}

      iex> alias DocSpec.Core.EPUB.Writer.XHTML
      iex> XHTML.from_html({"div", [{"class", "content"}], [{"p", [], ["Text"]}]})
      {"div", [{"class", "content"}], [{"p", [], ["Text"]}]}

      iex> alias DocSpec.Core.EPUB.Writer.XHTML
      iex> XHTML.from_html([{"h1", [], ["Title"]}, {"p", [], ["Content"]}])
      [{"h1", [], ["Title"]}, {"p", [], ["Content"]}]

      iex> alias DocSpec.Core.EPUB.Writer.XHTML
      iex> {"div", [], [{:comment, "Example"}, {"img", [{"src", "photo.jpg"}], []}, {"p", [], ["Text"]}]}
      ...> |> XHTML.from_html()
      {"div", [], ["", {"img", [{"src", "photo.jpg"}], []}, {"p", [], ["Text"]}]}

  """
  @spec from_html(nodes :: [Floki.html_node()]) :: [Saxy.XML.element()]
  def from_html(nodes) when is_list(nodes),
    do: nodes |> Enum.map(&from_html/1)

  def from_html({"th", attrs, children}),
    do: {
      "th",
      Enum.reject(attrs, fn {name, _} -> name == "abbr" end),
      from_html(children)
    }

  def from_html({tag, attrs, children}),
    do: {tag, attrs, from_html(children)}

  def from_html(node) when is_binary(node),
    do: node |> Floki.raw_html()

  def from_html(_node),
    do: ""

  defmodule Element do
    @doc """
    Creates an HTML element with XHTML and EPUB namespaces.

    ## Examples

        iex> alias DocSpec.Core.EPUB.Writer.XHTML.Element
        iex> Element.html([])
        {"html", [{"xmlns", "http://www.w3.org/1999/xhtml"}, {"xmlns:epub", "http://www.idpf.org/2007/ops"}], []}

        iex> alias DocSpec.Core.EPUB.Writer.XHTML.Element
        iex> Element.html([{"body", [], ["content"]}])
        {"html", [{"xmlns", "http://www.w3.org/1999/xhtml"}, {"xmlns:epub", "http://www.idpf.org/2007/ops"}], [{"body", [], ["content"]}]}

    """
    @spec html(children :: [Saxy.XML.element()]) :: Saxy.XML.element()
    def html(children) when is_list(children),
      do: {
        "html",
        [
          {"xmlns", "http://www.w3.org/1999/xhtml"},
          {"xmlns:epub", "http://www.idpf.org/2007/ops"}
        ],
        children
      }

    @doc """
    Creates a head element with stylesheet link and title.

    ## Examples

        iex> alias DocSpec.Core.EPUB.Writer.XHTML.Element
        iex> Element.head([])
        {"head", [], [{"link", [{"rel", "stylesheet"}, {"type", "text/css"}, {"href", "../css/style.css"}], []}, {"title", [], ["Document"]}]}

        iex> alias DocSpec.Core.EPUB.Writer.XHTML.Element
        iex> Element.head([{"meta", [{"name", "author"}], []}])
        {"head", [], [{"link", [{"rel", "stylesheet"}, {"type", "text/css"}, {"href", "../css/style.css"}], []}, {"title", [], ["Document"]}, {"meta", [{"name", "author"}], []}]}

    """
    @spec head(children :: [Saxy.XML.element()]) :: Saxy.XML.element()
    def head(children) when is_list(children),
      do: {
        "head",
        [],
        [
          {
            "link",
            [{"rel", "stylesheet"}, {"type", "text/css"}, {"href", "../css/style.css"}],
            []
          },
          {"title", [], ["Document"]}
        ] ++ children
      }

    @doc """
    Creates a body element for chapters or navigation.

    ## Examples

        iex> alias DocSpec.Core.EPUB.Writer.XHTML.Element
        iex> Element.body([{"h1", [], ["Chapter 1"]}], :chapter)
        {"body", [], [{"section", [{"epub:type", "chapter"}], [{"h1", [], ["Chapter 1"]}]}]}

        iex> alias DocSpec.Core.EPUB.Writer.XHTML.Element
        iex> Element.body([{"ol", [], []}], :nav)
        {"body", [], [{"nav", [{"epub:type", "toc"}, {"id", "toc"}], [{"ol", [], []}]}]}

    """
    @spec body(children :: [Saxy.XML.element()], context :: :nav | :chapter) :: Saxy.XML.element()
    def body(children, :chapter) when is_list(children),
      do: {"body", [], [{"section", [{"epub:type", "chapter"}], children}]}

    @spec body(children :: [Saxy.XML.element()], context :: :nav | :chapter) :: Saxy.XML.element()
    def body(children, :nav) when is_list(children),
      do: {"body", [], [{"nav", [{"epub:type", "toc"}, {"id", "toc"}], children}]}
  end
end
