defmodule DocSpec.Core.DOCX.Reader.Files do
  @moduledoc """
  This module provides functions to find specific files inside a Docx document.

  TODO: write proper tests for this module:
  1. extract a regular Zip file from fixtures
  2. Reader.Files.read("path/to/extracted/zip")
  3. assert that the files are found correctly and the correct `Reader.Files` struct is returned
  4. assert that the `Reader.Files` struct can be used to find the correct files:
    - `Reader.Files.document/1`
    - `Reader.Files.core_properties/1`
    - `Reader.Files.numberings/1`
    - `Reader.Files.styles/1`
    - `Reader.Files.relationships_of/2`
  """

  alias DocSpec.Core.DOCX.Reader
  alias DocSpec.Core.DOCX.Reader.{Files.ContentTypes, XML}

  @type t() :: %Reader.Files{
          dir: String.t(),
          files: [String.t()],
          types: ContentTypes.t()
        }

  @fields [:dir, :files, :types]
  @enforce_keys @fields
  defstruct @fields

  @doc """
  Read the contents of a directory containing an unzipped Docx file and parse the `[Content_Types].xml` file
  to return a `Reader.Files` struct that can be used with the rest of the functions in this module.
  """
  @spec read(String.t()) :: t()
  def read(dir) do
    files =
      dir
      |> Path.join("**/*")
      |> Path.wildcard()
      |> Enum.filter(&File.regular?/1)

    types =
      dir
      |> Path.join("[Content_Types].xml")
      |> XML.read!()
      |> ContentTypes.parse()

    %Reader.Files{dir: dir, files: files, types: types}
  end

  @content_type_core_properties "application/vnd.openxmlformats-package.core-properties+xml"
  @content_type_document "application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"
  @content_type_numbering "application/vnd.openxmlformats-officedocument.wordprocessingml.numbering+xml"
  @content_type_relations "application/vnd.openxmlformats-package.relationships+xml"
  @content_type_styles "application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"

  ## TODO: add these when we start needing them:
  # @content_type_theme "application/vnd.openxmlformats-officedocument.theme+xml"
  # @content_type_settings "application/vnd.openxmlformats-officedocument.wordprocessingml.settings+xml"
  # @content_type_extended_properties "application/vnd.openxmlformats-officedocument.extended-properties+xml"
  # @content_type_endnotes "application/vnd.openxmlformats-officedocument.wordprocessingml.endnotes+xml"
  # @content_type_footnotes "application/vnd.openxmlformats-officedocument.wordprocessingml.footnotes+xml"

  @spec document(Reader.Files.t()) :: String.t()
  def document(files = %Reader.Files{}),
    do: find_by_content_type(files, @content_type_document) |> hd()

  @spec core_properties(Reader.Files.t()) :: [String.t()]
  def core_properties(files = %Reader.Files{}),
    do: find_by_content_type(files, @content_type_core_properties)

  @spec numberings(Reader.Files.t()) :: [String.t()]
  def numberings(files = %Reader.Files{}),
    do: find_by_content_type(files, @content_type_numbering)

  @spec styles(Reader.Files.t()) :: [String.t()]
  def styles(files = %Reader.Files{}),
    do: find_by_content_type(files, @content_type_styles)

  @spec find_by_content_type(Reader.Files.t(), String.t()) :: [String.t()]
  def find_by_content_type(%Reader.Files{dir: dir, files: files, types: types}, content_type) do
    files
    |> Enum.filter(fn file ->
      relative_file = file |> String.trim_leading(dir)
      types |> ContentTypes.type(relative_file) == content_type
    end)
  end

  @spec relationships_of(Reader.Files.t(), filepath :: String.t()) :: String.t() | nil
  def relationships_of(%Reader.Files{dir: dir, files: files, types: types}, filepath)
      when is_binary(filepath) do
    rels_path =
      filepath
      |> Path.dirname()
      |> Path.join("_rels")
      |> Path.join(Path.basename(filepath) <> ".rels")

    result =
      files
      |> Enum.filter(fn file ->
        relative_file = file |> String.trim_leading(dir)
        file == rels_path and ContentTypes.type(types, relative_file) == @content_type_relations
      end)

    if result == [], do: nil, else: hd(result)
  end
end
