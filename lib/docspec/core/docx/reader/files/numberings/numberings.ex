defmodule DocSpec.Core.DOCX.Reader.Files.Numberings do
  @moduledoc """
  This module parses the numbering files (e.g. `word/numbering.xml`) in a Docx document
  into a map mapping `{id, level}` tuples to numbering definitions, represented by
  `DocSpec.Core.DOCX.Reader.AST.Numbering` structs.

  ## How does it work?

  Inside the numberings file, a set of numberings and abstract numberings are defined.
  The numberings inherit it's properties from an abstract numbering. An example of this
  is illustrated below.

  ```xml
  <?xml version="1.0" encoding="UTF-8"?>
  <w:numbering xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
    <w:abstractNum w:abstractNumId="990">
      <w:lvl w:ilvl="0">
        <w:start w:val="1"/>
        <w:numFmt w:val="bullet"/>
      </w:lvl>
      <w:lvl w:ilvl="1">
        <w:start w:val="1"/>
        <w:numFmt w:val="bullet"/>
      </w:lvl>
    </w:abstractNum>
    <w:num w:numId="1000">
      <w:abstractNumId w:val="990"/>
    </w:num>
    <w:num w:numId="1001">
      <w:abstractNumId w:val="990"/>
      <w:lvlOverride w:ilvl="0">
        <w:startOverride w:val="3"/>
      </w:lvlOverride>
    </w:num>
  </w:numbering>
  ```

  An abstract numbering can define a set of properties, which the numberings
  can inherit and/or override.
  """

  alias DocSpec.Core.DOCX.Reader.AST.{Numbering, NumberingProperties, ParagraphProperties}
  alias DocSpec.Core.DOCX.Reader.Files.Numberings.State

  @type t() :: %{{id :: String.t(), level :: integer()} => Numbering.t()}

  @doc """
  Get a numbering definition from a parsed map of numbering definitions by its ID and level.

  ## Examples

      iex> alias DocSpec.Core.DOCX.Reader.AST.Numbering
      iex> import DocSpec.Core.DOCX.Reader.Files.Numberings
      iex> numberings = %{
      ...>   {"3", 2} => %Numbering{id: "3", level: 2, format: "X", start: 3},
      ...>   {"3", 1} => %Numbering{id: "3", level: 1, format: "Y", start: 2},
      ...>   {"2", 1} => %Numbering{id: "2", level: 1, format: "Y", start: 2}}
      iex> get(numberings, "3", 1)
      %Numbering{id: "3", level: 1, format: "Y", start: 2}
      iex> get(numberings, "3", 5)
      nil
      iex> get(numberings, "5", 1)
      nil
  """
  @spec get(t(), id :: String.t(), level :: integer()) :: Numbering.t() | nil
  def get(numberings, id, level)
      when is_map(numberings) and is_binary(id) and is_integer(level) do
    numberings |> Map.get({id, level}, nil)
  end

  @doc """
  Get the numbering definition referred to by a `NumberingProperties` struct
  or the numbering properties embedded in a `ParagraphProperties` struct.

  ## Examples

      iex> alias DocSpec.Core.DOCX.Reader.AST.{Numbering, NumberingProperties, ParagraphProperties}
      iex> import DocSpec.Core.DOCX.Reader.Files.Numberings
      iex> numberings = %{
      ...>   {"3", 2} => %Numbering{id: "3", level: 2, format: "X", start: 3},
      ...>   {"3", 1} => %Numbering{id: "3", level: 1, format: "Y", start: 2},
      ...>   {"2", 1} => %Numbering{id: "2", level: 1, format: "Y", start: 2}}
      iex> num_props = %NumberingProperties{num_id: "3", ilvl: 1}
      iex> numberings |> get(num_props)
      %Numbering{id: "3", level: 1, format: "Y", start: 2}
      iex> numberings |> get(%ParagraphProperties{style_id: nil, num_properties: num_props, justification: nil})
      %Numbering{id: "3", level: 1, format: "Y", start: 2}
      iex> numberings |> get(nil)
      nil
  """
  @spec get(t(), NumberingProperties.t() | ParagraphProperties.t()) :: Numbering.t() | nil
  @spec get(t(), nil) :: nil
  def get(_, nil), do: nil

  def get(numberings, %ParagraphProperties{num_properties: num_properties}),
    do: numberings |> get(num_properties)

  def get(_numberings, %NumberingProperties{num_id: id, ilvl: level})
      when is_nil(id) or is_nil(level),
      do: nil

  def get(numberings, %NumberingProperties{num_id: id, ilvl: level}),
    do: numberings |> get(id, level)

  @doc """
  Parses the numbering definitions in a `word/numbering.xml` file into a map mapping
  `{id, level}` tuples to `DocSpec.Core.DOCX.Reader.AST.Numbering` structs.
  """
  @spec parse(Saxy.XML.element()) :: t()
  def parse({"w:numbering", _, children}) do
    children
    |> parse_numbering(%State{abstract_numberings: children |> parse_abstract_numbering()})
    |> State.get(:numberings)
    |> Enum.into(
      %{},
      fn
        numbering = %Numbering{id: id, level: level} -> {{id, level}, numbering}
      end
    )
  end

  @spec parse_numbering(Saxy.XML.element() | [Saxy.XML.element()], State.t()) :: State.t()
  defp parse_numbering(elements, state) when is_list(elements),
    do: elements |> Enum.reduce(state, &parse_numbering/2)

  defp parse_numbering({"w:num", attrs, children}, state = %State{}) do
    numbering_id = attrs |> SimpleForm.Attrs.get_value("w:numId")

    abstract_numbering_id =
      children
      |> SimpleForm.Element.find_by_name("w:abstractNumId")
      |> SimpleForm.Attrs.get_value("w:val")

    if is_nil(abstract_numbering_id) do
      state
    else
      numberings =
        state
        |> State.get(:abstract_numberings)
        |> Enum.filter(fn %Numbering{id: id} -> id == abstract_numbering_id end)
        |> Enum.map(fn numbering = %Numbering{} -> %{numbering | id: numbering_id} end)

      children
      |> parse_numbering(
        state
        |> State.prepend(:numberings, numberings)
        |> State.set(:numbering_id, numbering_id)
      )
    end
  end

  defp parse_numbering({"w:lvlOverride", attributes, children}, state = %State{}) do
    level = attributes |> SimpleForm.Attrs.get_value("w:ilvl") |> String.to_integer()
    children |> parse_numbering(state |> State.set(:level, level))
  end

  # either w:num -> w:lvlOverride -> w:lvl -> w:start
  # or: w:num -> w:lvlOverride -> w:startOverride
  defp parse_numbering(
         {name, attributes, _children},
         state = %State{numbering_id: numbering_id, level: level}
       )
       when name in ["w:start", "w:startOverride"] do
    start = attributes |> SimpleForm.Attrs.get_value("w:val") |> String.to_integer()

    state
    |> State.set(
      :numberings,
      state
      |> State.get(:numberings)
      |> Enum.map(fn
        numbering = %Numbering{id: ^numbering_id, level: ^level} ->
          %{numbering | start: start}

        other ->
          other
      end)
    )
  end

  # w:num -> w:lvlOverride -> w:lvl
  defp parse_numbering(
         {"w:lvl", attributes, children},
         state = %State{numbering_id: numbering_id, level: level}
       ) do
    new_level = attributes |> SimpleForm.Attrs.get_value("w:ilvl") |> String.to_integer()

    state =
      state
      |> State.set(
        :numberings,
        state
        |> State.get(:numberings)
        |> Enum.map(fn
          numbering = %Numbering{id: ^numbering_id, level: ^level} ->
            %{numbering | level: new_level}

          other ->
            other
        end)
      )
      |> State.set(:level, new_level)

    children |> parse_numbering(state)
  end

  # w:num -> w:lvlOverride -> w:lvl -> w:numFmt
  defp parse_numbering(
         {"w:numFmt", attributes, _children},
         state = %State{numbering_id: numbering_id, level: level}
       ) do
    format = attributes |> SimpleForm.Attrs.get_value("w:val", "decimal")

    state
    |> State.set(
      :numberings,
      state
      |> State.get(:numberings)
      |> Enum.map(fn
        numbering = %Numbering{id: ^numbering_id, level: ^level} ->
          %{numbering | format: format}

        other ->
          other
      end)
    )
  end

  defp parse_numbering({_, _, children}, state = %State{}),
    do: children |> parse_numbering(state)

  @type abstract_numberings() :: [Numbering.t()]

  @spec parse_abstract_numbering(Saxy.XML.element() | [Saxy.XML.element()]) ::
          abstract_numberings()

  defp parse_abstract_numbering(elements) when is_list(elements),
    do: elements |> Enum.flat_map(&parse_abstract_numbering/1)

  defp parse_abstract_numbering({"w:abstractNum", attrs, children}) do
    numbering_id = attrs |> SimpleForm.Attrs.get_value("w:abstractNumId")

    children
    |> Enum.flat_map(&parse_abstract_numbering(&1, numbering_id))
  end

  defp parse_abstract_numbering(_),
    do: []

  @spec parse_abstract_numbering(Saxy.XML.element(), String.t()) :: abstract_numberings()
  defp parse_abstract_numbering({"w:lvl", attrs, children}, numbering_id) do
    level =
      attrs
      |> SimpleForm.Attrs.get_value("w:ilvl")
      |> String.to_integer()

    start =
      children
      |> SimpleForm.Element.find_by_name("w:start")
      |> SimpleForm.Attrs.get_value("w:val", "1")
      |> String.to_integer()

    format =
      children
      |> SimpleForm.Element.find_by_name("w:numFmt")
      |> SimpleForm.Attrs.get_value("w:val", "decimal")

    [%Numbering{id: numbering_id, level: level, format: format, start: start}]
  end

  defp parse_abstract_numbering(_, _), do: []

  @doc """
  Reads a (list of) Docx numbering.xml file(s) at the given path(s) and parses it/them into
  a single map as returned by `parse/1`.
  """
  @spec read!(filepath :: String.t()) :: t()
  @spec read!(filepaths :: [String.t()]) :: t()
  def read!(filepath) when is_binary(filepath),
    do: filepath |> DocSpec.Core.DOCX.Reader.XML.read!() |> parse()

  def read!([]),
    do: %{}

  def read!([filepath | rest]),
    do: read!(filepath) |> Map.merge(read!(rest))
end
