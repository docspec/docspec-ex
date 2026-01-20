defmodule DocSpec.Core.EPUB.Writer do
  @moduledoc """
  Main entry point for converting DocSpec documents to EPUB 3.3 format.

  This module provides the high-level API for generating EPUB files from
  DocSpec document specifications. It coordinates the conversion process by:

  1. Creating the package manifest (OPF)
  2. Converting document content to XHTML chapters
  3. Generating navigation files (XHTML nav and NCX)
  4. Bundling everything into a valid EPUB ZIP archive

  ## EPUB 3.3 Compliance

  The generated EPUBs follow the EPUB 3.3 specification while maintaining
  backward compatibility with EPUB 2 through the inclusion of NCX navigation.

  ## Usage

  Convert a document to an EPUB file:

      document = %DocSpec.Spec.Document{...}
      DocSpec.Core.EPUB.Writer.convert!(document, "output.epub")

  Or get the EPUB as a binary for streaming:

      {:ok, epub_binary} = DocSpec.Core.EPUB.Writer.convert!(document)
  """

  alias DocSpec.Core.EPUB.Writer, as: EPUB
  alias DocSpec.Spec.{Document, DocumentSpecification}

  @doc """
  Converts a document specification to EPUB format and writes it to a file.

  Creates a complete EPUB 3.3 file at the specified path. The path can be
  provided as either a String or charlist.

  ## Parameters

  - `spec` - The DocSpec document specification to convert
  - `path` - The file path where the EPUB should be written (String or charlist)

  ## Returns

  - `:ok` on successful write
  - `{:error, reason}` if the operation fails

  ## Examples

      iex> alias DocSpec.Core.EPUB.Writer, as: EPUB
      iex> alias DocSpec.Spec.{Document, DocumentSpecification}
      iex> _spec = %DocumentSpecification{document: %Document{id: "test-123", children: []}}
      iex> # EPUB.convert!(spec, "/tmp/test.epub")
      iex> # :ok

  """
  @spec convert!(spec :: DocumentSpecification.t(), path :: String.t() | charlist()) ::
          :ok | {:error, term()}
  def convert!(%DocumentSpecification{document: doc}, path) when is_binary(path) or is_list(path),
    do: doc |> make_bundle() |> EPUB.ZIP.write!(path)

  @doc """
  Converts a document specification to EPUB format and returns it as a binary.

  Creates a complete EPUB 3.3 file in memory without writing to disk.
  Useful for serving EPUBs over HTTP or further processing.

  ## Parameters

  - `spec` - The DocSpec document specification to convert

  ## Returns

  - `{:ok, binary}` containing the EPUB file data
  - `{:error, reason}` if the operation fails

  ## Examples

      iex> alias DocSpec.Core.EPUB.Writer, as: EPUB
      iex> alias DocSpec.Spec.{Document, DocumentSpecification}
      iex> spec = %DocumentSpecification{document: %Document{id: "test-456", children: []}}
      iex> {:ok, epub_data} = EPUB.convert!(spec)
      iex> is_binary(epub_data)
      true

  """
  @spec convert!(spec :: DocumentSpecification.t()) :: {:ok, binary()} | {:error, term()}
  def convert!(%DocumentSpecification{document: doc}),
    do: doc |> make_bundle() |> EPUB.ZIP.write!()

  @spec make_bundle(doc :: Document.t()) :: EPUB.Bundle.t()
  defp make_bundle(doc = %Document{}),
    do: %EPUB.Bundle{
      package: EPUB.Package.convert(doc),
      document: EPUB.Chapter.convert(doc),
      nav_xhtml: EPUB.TableOfContents.create_xhtml(),
      nav_ncx: EPUB.TableOfContents.create_ncx(doc),
      assets: doc.assets
    }
end
