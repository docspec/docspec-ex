defmodule DocSpec.Core.DOCX.Reader.Files.Relationship do
  @moduledoc """
  This module provides functions for reading and parsing relationships files (e.g. `word/_rels/document.xml.rels`)
  into a map mapping `{id, type}` tuples to `DocSpec.Core.DOCX.Reader.AST.Relationship` structs.
  """

  alias DocSpec.Core.DOCX.Reader.AST.Relationship

  @rel_type_hyperlink "http://schemas.openxmlformats.org/officeDocument/2006/relationships/hyperlink"
  @rel_type_image "http://schemas.openxmlformats.org/officeDocument/2006/relationships/image"

  @type t() :: %{{id :: String.t(), type :: rel_type()} => relation :: Relationship.t()}

  @type rel_type() :: String.t() | :hyperlink | :image

  @doc """
  Get a relationship by its ID and type from a parsed map of relationships. The type can be a string
  equal to the relationship's `Type` attribute, or one of the atoms `:hyperlink` or `:image` to match
  their respective types.
  """
  @spec get(t(), id :: nil, type :: rel_type()) :: nil
  @spec get(t(), id :: nil, type :: rel_type(), default :: default) :: default when default: var
  @spec get(t(), id :: String.t(), type :: rel_type()) :: Relationship.t() | nil
  @spec get(t(), id :: String.t(), type :: rel_type(), default :: default) ::
          Relationship.t() | default
        when default: var
  def get(rels, id, type, default \\ nil)
  def get(_rels, nil, _, default), do: default
  def get(rels, id, :hyperlink, default), do: get(rels, id, @rel_type_hyperlink, default)
  def get(rels, id, :image, default), do: get(rels, id, @rel_type_image, default)

  def get(rels, id, type, default) when is_map(rels) and is_binary(id) and is_binary(type),
    do: rels |> Map.get({id, type}, default)

  @doc """
  Get the target of a relationship by its ID and type from a parsed map of relationships.
  The type can be a string equal to the relationship's `Type` attribute, or one of the atoms
  `:hyperlink` or `:image` to match their respective types.
  """
  @spec get_target(t(), id :: nil, type :: rel_type()) :: nil
  @spec get_target(t(), id :: nil, type :: rel_type(), default :: default) :: default
        when default: var
  @spec get_target(t(), id :: String.t(), type :: rel_type()) :: String.t() | nil
  @spec get_target(t(), id :: String.t(), type :: rel_type(), default :: default) ::
          String.t() | default
        when default: var
  def get_target(rels, id, type, default \\ nil) when is_map(rels) do
    case rels |> get(id, type) do
      nil -> default
      %Relationship{target: target} -> target
    end
  end

  @doc """
  Parses the contents of a relationships file (a `Relationships` XML element) into a map mapping
  `{id, type}` tuples to `DocSpec.Core.DOCX.Reader.Files.Relationship` structs.
  """
  @spec parse(Saxy.XML.element() | [Saxy.XML.element()]) :: t()
  def parse([]), do: %{}
  def parse([string | rest]) when is_binary(string), do: parse(rest)
  def parse([element | rest]), do: Map.merge(parse(element), parse(rest))

  def parse({"Relationships", _, children}), do: parse(children)

  def parse({"Relationship", attrs, _}) do
    [id, type, target, target_mode] =
      attrs |> SimpleForm.Attrs.get_many_value(["Id", "Type", "Target", "TargetMode"])

    %{{id, type} => %Relationship{id: id, type: type, target: target, target_mode: target_mode}}
  end

  def parse({_, _, children}), do: parse(children)

  @doc """
  Reads a Docx relationships (`.xml.rels`) file at the given path and parses it into
  a single map as returned by `parse/1`.

  Note that multiple relationships files may reuse ID and type combinations from each other,
  so be careful of merging the results of reading multiple relationships files.
  """
  @spec read!(filepath :: String.t()) :: t()
  def read!(filepath) when is_binary(filepath) do
    filepath |> DocSpec.Core.DOCX.Reader.XML.read!() |> parse()
  end
end
