defmodule DocSpec.Core.DOCX.Reader.Files.CoreProperties do
  @moduledoc """
  This module parses the core properties (`docProps/core.xml`) file in a Docx document
  into a simple key-value map.
  """

  alias DocSpec.Spec.{Author, DocumentMeta}

  @type t :: %{String.t() => String.t()}

  @doc """
  Parses the contents of a Docx core properties (`docProps/core.xml`) file into a key-value map of all the properties.

  ## Examples

      iex> DocSpec.Core.DOCX.Reader.Files.CoreProperties.parse(
      ...>   {"cp:coreProperties", [], [
      ...>     {"dc:title", [], ["Jesus He Knows Me"]},
      ...>     {"dc:creator", [], ["Genesis"]},
      ...>     {"cp:keywords", [], ["song, music, satire, televangelists, religious hypocrisy, pop-rock, social commentary"]},
      ...>     {"dc:description", [], ["Satirical song that mocks televangelists and religious hypocrisy, blending upbeat, catchy pop-rock with biting social commentary."]},
      ...>     {"cp:lastModifiedBy", [], ["Phil Collins"]},
      ...>     {"cp:revision", [], ["42"]},
      ...>     {"dcterms:created", [{"xsi:type", "dcterms:W3CDTF"}], ["1991-03-15T07:56:00Z"]},
      ...>     {"dcterms:modified", [{"xsi:type", "dcterms:W3CDTF"}], ["1991-07-10T01:23:01Z"]}
      ...>   ]}
      ...> )
      %{
        "dc:title" => "Jesus He Knows Me",
        "dc:creator" => "Genesis",
        "cp:keywords" => "song, music, satire, televangelists, religious hypocrisy, pop-rock, social commentary",
        "dc:description" => "Satirical song that mocks televangelists and religious hypocrisy, blending upbeat, catchy pop-rock with biting social commentary.",
        "cp:lastModifiedBy" => "Phil Collins",
        "cp:revision" => "42",
        "dcterms:created" => "1991-03-15T07:56:00Z",
        "dcterms:modified" => "1991-07-10T01:23:01Z"
      }
  """
  @spec parse(Saxy.XML.element() | [Saxy.XML.element()]) :: t()
  def parse({"cp:coreProperties", _, children}) do
    children
    |> Enum.filter(&is_tuple/1)
    |> Map.new(fn {key, _, value} -> {key, value |> Enum.join()} end)
  end

  # "coreProperties" may also be used as the root element instead of "cp:coreProperties",
  # see Docx fixture pandoc-alternate_document_path.docx
  def parse({"coreProperties", attrs, children}),
    do: parse({"cp:coreProperties", attrs, children})

  def parse([]), do: %{}
  def parse([string | rest]) when is_binary(string), do: parse(rest)
  def parse([element | rest]), do: parse(element) |> Map.merge(parse(rest))

  @doc """
  Reads a (list of) Docx core properties file(s) at the given path(s) and parses it/them into a key-value map of all
  the properties.
  """
  @spec read!(filepath :: String.t()) :: t()
  @spec read!(filepaths :: [String.t()]) :: t()
  def read!(filepath) when is_binary(filepath) do
    filepath |> DocSpec.Core.DOCX.Reader.XML.read!() |> parse()
  end

  def read!([]), do: %{}
  def read!([filepath | rest]), do: Map.merge(read!(filepath), read!(rest))

  @doc """
  Converts a map of core properties into a DocumentMeta struct to be set as metadata on the root document.
  """
  @spec convert(t()) :: DocumentMeta.t() | nil
  def convert(props) when is_map(props) do
    title = props |> Map.get("dc:title", "") |> String.trim() |> empty_as_nil()
    creator = props |> Map.get("dc:creator", "") |> String.trim() |> empty_as_nil()
    description = props |> Map.get("dc:description", "") |> String.trim() |> empty_as_nil()
    language = props |> Map.get("dc:language", "") |> String.trim() |> empty_as_nil()

    authors = if creator, do: [%Author{name: creator}], else: []

    if title || creator || description || language do
      %DocumentMeta{
        title: title,
        authors: authors,
        description: description,
        language: language
      }
    else
      nil
    end
  end

  @spec empty_as_nil(String.t()) :: String.t() | nil
  defp empty_as_nil(""), do: nil
  defp empty_as_nil(value), do: value
end
