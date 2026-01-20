defmodule DocSpec.Core.DOCX.Reader.Convert.Paragraph do
  @moduledoc """
  This module defines utility functions for converting Paragraphs.
  """

  import DocSpec.Core.DOCX.Reader.{AST.Style, State, Util.Helpers}

  alias DocSpec.Core.DOCX.Reader
  alias DocSpec.Core.DOCX.Reader.{AST, Files.Numberings, State}

  alias DocSpec.Spec.{
    BlockQuotation,
    DefinitionDetails,
    DefinitionList,
    DefinitionTerm,
    Heading,
    Image,
    ListItem,
    OrderedList,
    Paragraph,
    Preformatted,
    UnorderedList
  }

  # Skip empty paragraphs.
  # TODO: move DocSpec.Core.Validation.Content to a shared location so we can use its visible_text/1 function here
  @doc """
  Convert paragraph-based elements such as definitions, lists, paragraphs, headings.
  """
  @type conversion() :: {resources :: [struct()], state :: State.t()}
  @spec convert(
          children :: [struct()],
          accumulator :: conversion(),
          docx :: Reader.t(),
          style :: AST.Style.t(),
          paragraph_properties :: AST.ParagraphProperties.t() | nil,
          numbering_definition :: AST.Numbering.t() | nil
        ) :: conversion()
  def convert([], {resources, state}, _docx, _style, _paragraph_properties, _numbering_definition) do
    {resources, state}
  end

  # If the paragraph only contains one image, unwrap the image.
  def convert(
        [image = %Image{}],
        {resources, state},
        _docx,
        _style,
        _paragraph_properties,
        _numbering_definition
      ) do
    {resources |> add(image), state}
  end

  # Paragraphs with style type :definition_term are converted to DefinitionTerm.
  def convert(
        children,
        {resources, state},
        _docx,
        style,
        _paragraph_properties,
        _numbering_definition
      )
      when is_definition_term(style) do
    details =
      %DefinitionList{}
      |> add_child(%DefinitionTerm{} |> add_children(children))

    {resources |> add(details), state}
  end

  # Paragraphs with style type :definition are converted to DefinitionDetails.
  def convert(
        children,
        {resources, state},
        _docx,
        style,
        _paragraph_properties,
        _numbering_definition
      )
      when is_definition(style) do
    details =
      %DefinitionList{}
      |> add_child(%DefinitionDetails{} |> add_children(children))

    {resources |> add(details), state}
  end

  # Paragraphs with style type :title are converted to headings with level 0.
  def convert(
        children,
        {resources, state},
        _docx,
        style,
        _paragraph_properties,
        _numbering_definition
      )
      when is_title(style) do
    heading = %Heading{level: 0} |> add_children(children)
    {resources |> add(heading), state |> set(:has_title, true)}
  end

  # Paragraphs with style type :heading are converted to headings with the appropriate level.
  def convert(
        children,
        {resources, state},
        _docx,
        style,
        _paragraph_properties,
        _numbering_definition
      )
      when is_heading(style) do
    level = style |> AST.Style.heading_level()
    heading = %Heading{level: level} |> add_children(children)
    {resources |> add(heading), state}
  end

  # Paragraphs with style type :blockquote are converted to paragraphs wrapped in a BlockQuotation element.
  def convert(
        children,
        {resources, state},
        _docx,
        style,
        _paragraph_properties,
        _numbering_definition
      )
      when is_blockquote(style) do
    blockquote = %BlockQuotation{} |> add_child(%Paragraph{} |> add_children(children))
    {resources |> add(blockquote), state}
  end

  # Paragraphs with style type :code are converted to Preformatted.
  def convert(
        children,
        {resources, state},
        _docx,
        style,
        _paragraph_properties,
        _numbering_definition
      )
      when is_code(style) do
    preformatted = %Preformatted{} |> add_children(children |> remove_code_style())
    {resources |> add(preformatted), state}
  end

  # Paragraphs where the numbering definition is not nil, are actually list items.
  def convert(
        children,
        {resources, state},
        docx,
        _style,
        _paragraph_properties,
        numbering = %AST.Numbering{}
      ) do
    list_children =
      %ListItem{}
      |> add_child(%Paragraph{} |> add_children(children))
      |> List.wrap()

    {resources, state}
    |> add_list(list_children, docx, numbering)
  end

  # If none of the other conditions apply, then this is just a regular paragraph.
  def convert(
        children,
        {resources, state},
        _docx,
        _style,
        paragraph_properties,
        _numbering_definition
      ) do
    paragraph =
      %Paragraph{}
      |> add_children(children)
      |> set_justification(paragraph_properties)

    {resources |> add(paragraph), state}
  end

  @spec set_justification(
          paragraph :: Paragraph.t(),
          properties :: AST.ParagraphProperties.t() | nil
        ) :: Paragraph.t()
  defp set_justification(paragraph = %Paragraph{}, nil),
    do: paragraph

  defp set_justification(paragraph = %Paragraph{}, %AST.ParagraphProperties{
         justification: justification
       }) do
    alignment = justification_string_value(justification)

    if is_nil(alignment) do
      paragraph
    else
      %Paragraph{paragraph | text_alignment: alignment}
    end
  end

  @spec justification_string_value(AST.ParagraphProperties.justification() | nil) ::
          String.t() | nil
  defp justification_string_value(nil),
    do: nil

  defp justification_string_value(:left),
    do: "left"

  defp justification_string_value(:center),
    do: "center"

  defp justification_string_value(:right),
    do: "right"

  defp justification_string_value(:both),
    do: "justify"

  @type spec_list_children() :: [ListItem.t()]
  @type spec_list() :: OrderedList.t() | UnorderedList.t()

  @spec construct_list(numbering :: AST.Numbering.t(), children :: spec_list_children()) ::
          spec_list()
  defp construct_list(numbering_definition = %AST.Numbering{}, children \\ [])
       when is_list(children) do
    numbering_definition
    |> AST.Numbering.to_list()
    |> add_children(children)
    |> add_id()
  end

  @spec add_to_list(
          list,
          children :: spec_list_children(),
          docx :: Reader.t(),
          numbering_id :: String.t(),
          level :: integer(),
          current_level :: integer()
        ) :: list
        when list: spec_list() | ListItem.t()

  # Recursively adds content to a list. Iterates recursively over the tree of children
  # until the correct level is reached. When that happens, add the content to the List Item.
  defp add_to_list(list, children, docx, numbering_id, level, current_level \\ 0)

  # When the correct level is reached, you may now add the content to the list.
  defp add_to_list(list = %type{}, children, _docx, _numbering_id, level, current_level)
       when is_list(children) and is_integer(level) and
              type in [OrderedList, UnorderedList] and
              current_level >= level,
       do: list |> add_children(children)

  # When a list is found without item, place a list item so we can add our content to there.
  defp add_to_list(
         list = %type{children: []},
         children,
         docx = %Reader{},
         numbering_id,
         level,
         current_level
       )
       when is_list(children) and is_binary(numbering_id) and is_integer(level) and
              is_integer(current_level) and type in [OrderedList, UnorderedList],
       do:
         list
         |> add_child(%ListItem{})
         |> add_to_list(children, docx, numbering_id, level, current_level)

  # When a list is found with an item, we can add our content to that item.
  defp add_to_list(
         list = %type{children: [list_item = %ListItem{} | other_children]},
         children,
         docx = %Reader{},
         numbering_id,
         level,
         current_level
       )
       when is_binary(numbering_id) and is_integer(level) and
              is_integer(current_level) and type in [OrderedList, UnorderedList],
       do: %{
         list
         | children: [
             list_item |> add_to_list(children, docx, numbering_id, level, current_level)
             | other_children
           ]
       }

  # When a list item is found with a list, add our content to that list.
  defp add_to_list(
         list_item = %ListItem{children: [list = %type{} | others]},
         children,
         docx = %Reader{},
         numbering_id,
         level,
         current_level
       )
       when is_list(children) and is_binary(numbering_id) and is_integer(level) and
              is_integer(current_level) and type in [OrderedList, UnorderedList],
       do: %{
         list_item
         | children: [
             list |> add_to_list(children, docx, numbering_id, level, current_level + 1) | others
           ]
       }

  # When a list item is found without a list, add our list to that item.
  defp add_to_list(
         list_item = %ListItem{},
         children,
         docx = %Reader{},
         numbering_id,
         level,
         current_level
       )
       when is_list(children) and is_binary(numbering_id) and is_integer(level) and
              is_integer(current_level),
       do:
         list_item
         |> add_child(
           docx.numberings
           |> Numberings.get(numbering_id, current_level + 1)
           |> construct_list()
         )
         |> add_to_list(children, docx, numbering_id, level, current_level)

  @spec add_list(
          acc :: conversion(),
          children :: spec_list_children(),
          docx :: Reader.t(),
          numbering_definition :: AST.Numbering.t()
        ) :: conversion()
  defp add_list(
         {[last = %type{} | resources], state = %State{numbering_id: numbering_id}},
         children,
         docx = %Reader{},
         numbering = %AST.Numbering{id: numbering_id}
       )
       when type in [OrderedList, UnorderedList] do
    {[last |> add_to_list(children, docx, numbering.id, numbering.level) | resources], state}
  end

  defp add_list(
         {resources, state = %State{}},
         children,
         docx = %Reader{},
         numbering = %AST.Numbering{}
       ) do
    {
      resources
      |> add(
        docx.numberings
        |> Numberings.get(numbering.id, 0)
        |> adjust_numbering_start(state)
        |> construct_list()
      ),
      state
      |> set(:numbering_id, numbering.id)
    }
    |> add_list(children, docx, numbering)
  end

  @spec adjust_numbering_start(numbering :: AST.Numbering.t(), state :: State.t()) ::
          AST.Numbering.t()
  defp adjust_numbering_start(
         numbering = %AST.Numbering{id: id, start: start},
         %State{numbering_id: id, last_root_list_count: surplus}
       ),
       do: %AST.Numbering{numbering | start: start + surplus}

  defp adjust_numbering_start(numbering = %AST.Numbering{}, _state = %State{}),
    do: numbering

  @spec remove_code_style(elements :: [struct()]) :: [struct()]
  defp remove_code_style(elements) when is_list(elements),
    do: elements |> Enum.map(&remove_code_style/1)

  @spec remove_code_style(element :: struct()) :: struct()
  defp remove_code_style(element = %{styles: styles = %DocSpec.Spec.Styles{code: true}}),
    do: %{element | styles: %{styles | code: false}}

  defp remove_code_style(element),
    do: element
end
