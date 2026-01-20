defmodule DocSpec.Core.EPUB.Writer.ZIP do
  @moduledoc """
  Creates EPUB ZIP archives from bundle components.

  This module handles the serialization of an EPUB bundle into a valid EPUB
  (ZIP) archive file. It ensures proper structure including:

  - Uncompressed mimetype file (must be first)
  - META-INF container metadata
  - OEBPS content and navigation files
  - Proper compression for various file types

  The module can write EPUBs either to disk or to memory as a binary.
  """

  alias DocSpec.Core.EPUB.Writer, as: EPUB

  @prolog [version: "1.0", encoding: "UTF-8"]

  @zip_opts [
    compress: [
      ~c".css",
      ~c".js",
      ~c".html",
      ~c".xhtml",
      ~c".ncx",
      ~c".opf",
      ~c".jpg",
      ~c".png",
      ~c".xml"
    ],
    extra: []
  ]

  @container_xml """
  <?xml version="1.0" encoding="UTF-8"?>
  <container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
    <rootfiles>
      <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
    </rootfiles>
  </container>
  """

  @ibooks_xml """
  <?xml version="1.0" encoding="UTF-8"?>
  <display_options><platform name="*"><option name="specified-fonts">true</option></platform></display_options>
  """

  @css ""

  @doc """
  Writes an EPUB bundle to a file at the given path.

  Creates a valid EPUB file at the specified path. The path can be provided
  as either a String or charlist. The EPUB will contain all necessary
  components including mimetype, container.xml, content.opf, navigation
  files, and the document content.

  ## Parameters

  - `archive` - The EPUB bundle to write
  - `path` - The file path (String or charlist) where the EPUB should be written

  ## Returns

  - `:ok` on successful write
  - `{:error, reason}` if the write fails

  ## Examples

      iex> # alias DocSpec.Core.EPUB.Writer, as: EPUB
      iex> # bundle = %EPUB.Bundle{...}
      iex> # EPUB.ZIP.write!(bundle, "/tmp/output.epub")
      iex> # :ok

  """
  @spec write!(archive :: EPUB.Bundle.t(), path :: String.t()) :: :ok | {:error, term()}
  def write!(archive = %EPUB.Bundle{}, path) when is_binary(path),
    do: write!(archive, String.to_charlist(path))

  @spec write!(archive :: EPUB.Bundle.t(), path :: charlist()) :: :ok | {:error, term()}
  def write!(archive = %EPUB.Bundle{}, path) when is_list(path) do
    case :zip.create(path, to_entries!(archive), @zip_opts) do
      {:ok, _filename_charlist} ->
        :ok

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Writes an EPUB bundle to memory and returns the binary.

  Creates a valid EPUB archive in memory without writing to disk.
  Useful for streaming EPUBs over HTTP or further processing.

  ## Parameters

  - `archive` - The EPUB bundle to convert to binary

  ## Returns

  - `{:ok, binary}` containing the EPUB file data
  - `{:error, reason}` if the operation fails

  ## Examples

      iex> # alias DocSpec.Core.EPUB.Writer, as: EPUB
      iex> # bundle = %EPUB.Bundle{...}
      iex> # {:ok, epub_binary} = EPUB.ZIP.write!(bundle)
      iex> # is_binary(epub_binary)
      iex> # true

  """
  @spec write!(archive :: EPUB.Bundle.t()) :: {:ok, binary()} | {:error, term()}
  def write!(archive = %EPUB.Bundle{}) do
    case :zip.create(~c"mem", to_entries!(archive), [:memory | @zip_opts]) do
      {:ok, {_name, zip_bin}} ->
        {:ok, zip_bin}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec to_entries!(archive :: EPUB.Bundle.t()) ::
          [{charlist(), String.t()}]
  defp to_entries!(epub = %EPUB.Bundle{}) do
    [
      # MUST be first, MUST be uncompressed, MUST be exactly this content
      {~c"mimetype", "application/epub+zip"},
      {~c"META-INF/container.xml", @container_xml},
      {~c"META-INF/com.apple.ibooks.display-options.xml", @ibooks_xml},
      {~c"OEBPS/content.opf", Saxy.encode!(epub.package, @prolog)},
      {~c"OEBPS/text/document.xhtml", Saxy.encode!(epub.document, @prolog)},
      {~c"OEBPS/text/nav.xhtml", Saxy.encode!(epub.nav_xhtml, @prolog)},
      {~c"OEBPS/toc.ncx", Saxy.encode!(epub.nav_ncx, @prolog)},
      {~c"OEBPS/css/style.css", @css}
    ] ++
      Enum.map(
        epub.assets,
        fn asset = %DocSpec.Spec.Asset{} ->
          {asset |> EPUB.Asset.path(:from_root) |> String.to_charlist(),
           Base.decode64!(asset.data)}
        end
      )
  end
end
