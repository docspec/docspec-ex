defmodule DocSpec.Core.EPUB.Writer.Package do
  @moduledoc """
  Generates EPUB package documents (OPF files).

  This module creates the `OEBPS/content.opf` file, which is the central
  manifest file in an EPUB. The package document contains:

  - Metadata (title, author, language, identifiers, modification date)
  - Manifest (list of all resources in the EPUB)
  - Spine (reading order of content documents)

  The package follows the EPUB 3.3 specification and uses Dublin Core
  metadata elements.
  """

  alias DocSpec.Core.EPUB.Writer, as: EPUB
  alias DocSpec.Spec.{Asset, Author, Document, DocumentMeta}

  @purl_prefix "http://purl.org/dc/elements/1.1/"
  @media_type_html "application/xhtml+xml"
  @media_type_css "text/css"
  @media_type_ncx "application/x-dtbncx+xml"

  @unique_id_prop "uid"

  @type t() :: Saxy.XML.element()

  @doc """
  Converts a document to an EPUB package manifest (OPF).

  Generates the `OEBPS/content.opf` file, which is the central manifest
  of an EPUB. This includes metadata extracted from document metadata,
  a manifest of all resources, and the spine defining reading order.

  ## Parameters

  - `doc` - The DocSpec document to convert

  ## Returns

  A Saxy XML element representing the package document.

  ## Examples

      iex> alias DocSpec.Core.EPUB.Writer.Package
      iex> alias DocSpec.Spec.Document
      iex> doc = %Document{id: "test-id", children: []}
      iex> {"package", _attrs, _children} = Package.convert(doc)
  """
  @spec convert(doc :: Document.t()) :: t()
  def convert(doc = %Document{}) do
    {
      "package",
      [
        {"xmlns", "http://www.idpf.org/2007/opf"},
        {"version", "3.0"},
        {"unique-identifier", @unique_id_prop}
      ],
      [convert_metadata(doc), convert_manifest(doc), convert_spine()]
    }
  end

  @spec now_iso() :: String.t()
  defp now_iso,
    do: DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()

  @spec convert_metadata(doc :: Document.t()) :: Saxy.XML.element()
  defp convert_metadata(%Document{id: id, metadata: metadata}) do
    defaults = %{
      "identifier" => {"dc:identifier", [{"id", @unique_id_prop}], [id]},
      "language" => {"dc:language", [], ["en"]},
      "title" => {"dc:title", [], ["Document"]},
      "dcterms:modified" => {"meta", [{"property", "dcterms:modified"}], [now_iso()]}
    }

    metadata_map = extract_metadata(metadata, defaults)

    {
      "metadata",
      [{"xmlns:dc", @purl_prefix}],
      Map.values(metadata_map)
    }
  end

  @spec extract_metadata(DocumentMeta.t() | nil, map()) :: map()
  defp extract_metadata(nil, defaults), do: defaults

  defp extract_metadata(meta = %DocumentMeta{}, defaults) do
    defaults
    |> maybe_put_title(meta.title)
    |> maybe_put_language(meta.language)
    |> maybe_put_creator(meta.authors)
    |> maybe_put_description(meta.description)
  end

  defp maybe_put_title(acc, title) when is_binary(title) and title != "",
    do: Map.put(acc, "title", {"dc:title", [], [title]})

  defp maybe_put_title(acc, _), do: acc

  defp maybe_put_language(acc, language) when is_binary(language) and language != "",
    do: Map.put(acc, "language", {"dc:language", [], [language]})

  defp maybe_put_language(acc, _), do: acc

  defp maybe_put_creator(acc, [%Author{name: name} | _]) when is_binary(name) and name != "",
    do: Map.put(acc, "creator", {"dc:creator", [], [name]})

  defp maybe_put_creator(acc, _), do: acc

  defp maybe_put_description(acc, description)
       when is_binary(description) and description != "",
       do: Map.put(acc, "description", {"dc:description", [], [description]})

  defp maybe_put_description(acc, _), do: acc

  @spec convert_manifest(doc :: Document.t()) ::
          Saxy.XML.element()
  defp convert_manifest(%Document{assets: assets}) do
    {
      "manifest",
      [],
      [
        {
          "item",
          [{"id", "css"}, {"href", "css/style.css"}, {"media-type", @media_type_css}],
          []
        },
        {
          "item",
          [
            {"id", "nav"},
            {"href", "text/nav.xhtml"},
            {"media-type", @media_type_html},
            {"properties", "nav"}
          ],
          []
        },
        {
          "item",
          [
            {"id", "ncx"},
            {"href", "toc.ncx"},
            {"media-type", @media_type_ncx}
          ],
          []
        },
        {
          "item",
          [{"id", "doc"}, {"href", "text/document.xhtml"}, {"media-type", @media_type_html}],
          []
        }
      ] ++
        Enum.map(
          assets,
          fn asset = %Asset{} ->
            {
              "item",
              [
                {"id", asset.id},
                {"href", EPUB.Asset.path(asset, :from_package)},
                {"media-type", asset.content_type}
              ],
              []
            }
          end
        )
    }
  end

  @spec convert_spine() :: Saxy.XML.element()
  defp convert_spine,
    do: {
      "spine",
      [{"toc", "ncx"}, {"page-progression-direction", "ltr"}],
      [{"itemref", [{"idref", "doc"}], []}]
    }
end
