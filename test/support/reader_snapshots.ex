defmodule DocSpec.Test.ReaderSnapshots do
  @moduledoc """
  Collects DocSpec JSON snapshots from all readers for use in writer tests.

  This module provides a unified way to get all DocSpec JSON fixtures that have
  been produced by reader tests (DOCX Reader, Tiptap Reader, etc.) so that
  writer tests can use them as input.
  """

  @readers %{
    "DocSpec.Core.DOCX.Reader" => "docx",
    "DocSpec.Core.Tiptap.Reader" => "tiptap"
  }

  @doc """
  Returns all DocSpec JSON snapshot paths from all readers.

  Each path points to an `expected.json` file that contains a valid DocSpec document
  in JSON format.

  ## Example

      iex> paths = DocSpec.Test.ReaderSnapshots.all()
      iex> Enum.any?(paths, &String.contains?(&1, "DOCX.Reader"))
      true
  """
  @spec all() :: [String.t()]
  def all do
    @readers
    |> Map.keys()
    |> Enum.flat_map(&snapshots_for_reader/1)
    |> Enum.filter(&File.regular?/1)
    |> Enum.sort()
  end

  @doc """
  Returns DocSpec JSON snapshot paths for a specific reader.

  ## Example

      iex> paths = DocSpec.Test.ReaderSnapshots.for_reader("DocSpec.Core.DOCX.Reader")
      iex> Enum.all?(paths, &String.contains?(&1, "DOCX.Reader"))
      true
  """
  @spec for_reader(String.t()) :: [String.t()]
  def for_reader(reader) when is_map_key(@readers, reader) do
    snapshots_for_reader(reader)
    |> Enum.filter(&File.regular?/1)
    |> Enum.sort()
  end

  @doc """
  Returns the list of reader module names.
  """
  @spec readers() :: [String.t()]
  def readers, do: Map.keys(@readers)

  @doc """
  Extracts the format name and fixture name from a snapshot path.

  Returns a tuple of {format, fixture_name} where format is a short name
  like "docx" or "tiptap".

  ## Example

      iex> DocSpec.Test.ReaderSnapshots.parse_path("test/snapshots/DocSpec.Core.DOCX.Reader/calibre-demo.docx/expected.json")
      {"docx", "calibre-demo.docx"}

      iex> DocSpec.Test.ReaderSnapshots.parse_path("test/snapshots/DocSpec.Core.Tiptap.Reader/blockquote.json/expected.json")
      {"tiptap", "blockquote.json"}
  """
  @spec parse_path(String.t()) :: {String.t(), String.t()}
  def parse_path(path) do
    parts = Path.split(path)
    reader_names = Map.keys(@readers)
    # Find the reader name (matches one of @readers)
    reader_idx = Enum.find_index(parts, &(&1 in reader_names))

    if reader_idx do
      reader = Enum.at(parts, reader_idx)
      fixture = Enum.at(parts, reader_idx + 1)
      format = Map.fetch!(@readers, reader)
      {format, fixture}
    else
      raise "Could not parse reader snapshot path: #{path}"
    end
  end

  @doc """
  Converts a reader module name to its short format name.

  ## Example

      iex> DocSpec.Test.ReaderSnapshots.format_name("DocSpec.Core.DOCX.Reader")
      "docx"
  """
  @spec format_name(String.t()) :: String.t()
  def format_name(reader) when is_map_key(@readers, reader) do
    Map.fetch!(@readers, reader)
  end

  defp snapshots_for_reader(reader) do
    Path.join(["test", "snapshots", reader])
    |> Path.join("*/expected.json")
    |> Path.wildcard()
  end
end
