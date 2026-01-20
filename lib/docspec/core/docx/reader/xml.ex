defmodule DocSpec.Core.DOCX.Reader.XML do
  @moduledoc """
  `DocSpec.Core.DOCX.Reader.XML` implements functions for reading and parsing XML files.
  """

  @doc """
  Reads an XML file at the given path and parses it into a `Saxy.XML.element` tuple.
  The file is assumed to be UTF-8 encoded and the BOM (Byte Order Mark) at the beginning of the file is trimmed.

  This function raises an error if the file cannot be read or if `Saxy` fails to parse the XML.
  """
  @spec read!(filename :: String.t()) :: Saxy.XML.element()
  def read!(filename) when is_binary(filename) do
    filename
    |> File.stream!([:trim_bom, encoding: :utf8])
    |> Enum.join()
    |> parse!()
  end

  @doc """
  Reads an XML file at the given path and parses it into a `Saxy.XML.element` tuple.
  The file is assumed to be UTF-8 encoded and the BOM (Byte Order Mark) at the beginning of the file is trimmed.

  This function returns `{:ok, element}` on success or `{:error, error}` with a `File.Error` or a `Saxy.ParseError`
  if the file cannot be read or if `Saxy` fails to parse the XML.
  """
  @spec read(filename :: String.t()) ::
          {:ok, Saxy.XML.element()} | {:error, Saxy.ParseError.t()}
  def read(filename) when is_binary(filename) do
    {:ok, read!(filename)}
  rescue
    error -> {:error, error}
  end

  @doc """
  Parses the given XML data into a `Saxy.XML.element` tuple.

  This function returns `{:ok, element}` on success or `{:error, error}` with a `Saxy.ParseError` if `Saxy` fails to parse the XML.
  """
  @spec parse(data :: String.t()) ::
          {:ok, Saxy.XML.element()} | {:error, Saxy.ParseError.t()}
  def parse(data) do
    data |> Saxy.SimpleForm.parse_string(expand_entity: :never)
  end

  @doc """
  Parses the given XML data into a `Saxy.XML.element` tuple.

  This function raises a `Saxy.ParseError` if `Saxy` fails to parse the XML.
  """
  @spec parse!(data :: String.t()) :: Saxy.XML.element()
  def parse!(data) do
    case parse(data) do
      {:ok, element} -> element
      {:error, error} -> raise error
    end
  end
end
