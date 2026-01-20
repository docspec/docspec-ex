defmodule DocSpec.Core.DOCX.Reader.Files.Styles do
  @moduledoc """
  This module parses the styles (e.g. `word/styles.xml`) files in a Docx document
  into a map mapping style IDs to `DocSpec.Core.DOCX.Reader.AST.Style` structs.
  """

  alias DocSpec.Core.DOCX.Reader.AST.Style

  @type t :: %{(style_id :: String.t()) => style :: Style.t()}

  @doc """
  Get a style by its ID from a parsed map of styles.
  """
  @spec get(t(), id :: nil) :: nil
  @spec get(t(), id :: String.t()) :: Style.t() | nil
  @spec get(t(), id :: String.t(), default :: default) :: Style.t() | default when default: var
  def get(styles, id, default \\ nil)
  def get(styles, nil, default) when is_map(styles), do: default

  # TODO: if Map.get() returns nil, get the style type from the based_on value
  def get(styles, id, default) when is_map(styles) and is_binary(id),
    do: Map.get(styles, id, default)

  @doc """
  Parses the styles from a `word/styles.xml` file into a map mapping style IDs to `DocSpec.Core.DOCX.Reader.AST.Style` structs.
  """
  @spec parse(Saxy.XML.element()) :: t()
  def parse([]), do: %{}
  def parse([string | rest]) when is_binary(string), do: parse(rest)
  def parse([style | rest]), do: Map.merge(parse(style), parse(rest))

  def parse({"w:styles", _attrs, children}), do: parse(children)

  def parse({"w:style", attrs, children}) do
    id = attrs |> SimpleForm.Attrs.get_value("w:styleId")

    name =
      children |> SimpleForm.Element.find_by_name("w:name") |> SimpleForm.Attrs.get_value("w:val")

    based_on =
      children
      |> SimpleForm.Element.find_by_name("w:basedOn")
      |> SimpleForm.Attrs.get_value("w:val")

    type = attrs |> SimpleForm.Attrs.get_value("w:type") |> convert_style_type(name, based_on)

    %{id => %Style{id: id, type: type, name: name, based_on: based_on}}
  end

  def parse({_, _, children}), do: parse(children)

  @doc """
  Reads a (list of) Docx styles.xml file(s) at the given path(s) and parses it/them into a single map
  of all the styles., as returned by `parse/1`.
  """
  @spec read!(filepath :: String.t()) :: t()
  @spec read!(filepaths :: [String.t()]) :: t()
  def read!(filepath) when is_binary(filepath) do
    filepath |> DocSpec.Core.DOCX.Reader.XML.read!() |> parse()
  end

  def read!([]), do: %{}
  def read!([filepath | rest]), do: Map.merge(read!(filepath), read!(rest))

  # Note: Docx style types that we've seen in the wild are: "character" | "paragraph" | "numbering" | "table"

  @spec convert_style_type(type :: String.t(), name :: String.t(), based_on :: String.t() | nil) ::
          Style.style_type()
  defp convert_style_type("paragraph", "Title", _), do: :title
  defp convert_style_type(_, "Quote", _), do: :blockquote
  defp convert_style_type(_, "Block Text", _), do: :blockquote
  defp convert_style_type(_, "Block Quote", _), do: :blockquote
  defp convert_style_type(_, "Block Quotation", _), do: :blockquote
  defp convert_style_type(_, "Intense Quote", _), do: :blockquote
  defp convert_style_type("paragraph", "Definition Term", _), do: :definition_term
  defp convert_style_type("paragraph", "Definition", _), do: :definition
  defp convert_style_type(_, "Plain Text", _), do: :code
  defp convert_style_type(_, "HTML Code", _), do: :code
  defp convert_style_type(_, "HTML Preformatted", _), do: :code
  defp convert_style_type(_, "HTML Sample", _), do: :code
  defp convert_style_type(_, "Source Code", _), do: :code
  defp convert_style_type(_, "Codeblock", _), do: :code
  defp convert_style_type(_, "Verbatim Char", _), do: :code

  defp convert_style_type("paragraph", name, _) do
    if heading_name?(name) do
      :heading
    else
      # TODO: implement looking up paragraph type using basedOn value
      :paragraph
    end
  end

  # TODO: implement converting character, numbering and table style types to something useful for the converter

  defp convert_style_type(_, _, _), do: :unknown

  @spec heading_name?(String.t()) :: boolean()
  defp heading_name?(name) when is_binary(name),
    do: name |> String.match?(~r/^heading (\d+)$/i)
end
