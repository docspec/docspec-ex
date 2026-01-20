defmodule DocSpec.Core.DOCX.Reader.Files.Document do
  @moduledoc """
  This module provides a function for reading a Docx document.xml file
  into a `DocSpec.Core.DOCX.Reader.Files.Document` struct.
  """

  alias DocSpec.Core.DOCX.Reader
  alias DocSpec.Core.DOCX.Reader.Files.Relationship

  @type t :: %__MODULE__{
          path: String.t(),
          root: Saxy.XML.element(),
          rels: Relationship.t()
        }
  @fields [:path, :root, :rels]
  @enforce_keys @fields
  defstruct @fields

  @doc """
  Reads a Docx document.xml file at the given path(s) and parses it into
  an `DocSpec.Core.DOCX.Reader.Files.Document` struct.
  """
  @spec read!(filepath :: String.t(), files :: Reader.Files.t()) :: t()
  def read!(filepath, files) when is_binary(filepath) do
    root = filepath |> DocSpec.Core.DOCX.Reader.XML.read!()

    rels =
      case files |> Reader.Files.relationships_of(filepath) do
        nil -> Relationship.parse([])
        rel_file -> Relationship.read!(rel_file)
      end

    %__MODULE__{path: filepath, root: root, rels: rels}
  end
end
