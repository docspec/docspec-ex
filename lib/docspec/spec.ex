defmodule DocSpec.Spec do
  @moduledoc """
  Helper functions for working with DocSpec Spec objects.
  """

  alias DocSpec.Spec.{
    BlockQuotation,
    DefinitionDetails,
    DefinitionList,
    DefinitionTerm,
    Document,
    Footnote,
    FootnoteReference,
    Heading,
    Image,
    Link,
    ListItem,
    Math,
    OrderedList,
    Paragraph,
    Preformatted,
    Table,
    TableCell,
    TableHeader,
    TableRow,
    Text,
    ThematicBreak,
    UnorderedList
  }

  @type object() ::
          BlockQuotation.t()
          | DefinitionDetails.t()
          | DefinitionList.t()
          | DefinitionTerm.t()
          | Document.t()
          | Footnote.t()
          | FootnoteReference.t()
          | Heading.t()
          | Image.t()
          | Link.t()
          | ListItem.t()
          | Math.t()
          | OrderedList.t()
          | Paragraph.t()
          | Preformatted.t()
          | Table.t()
          | TableCell.t()
          | TableHeader.t()
          | TableRow.t()
          | Text.t()
          | ThematicBreak.t()
          | UnorderedList.t()

  @objects [
    BlockQuotation,
    DefinitionDetails,
    DefinitionList,
    DefinitionTerm,
    Document,
    Footnote,
    FootnoteReference,
    Heading,
    Image,
    Link,
    ListItem,
    Math,
    OrderedList,
    Paragraph,
    Preformatted,
    Table,
    TableCell,
    TableHeader,
    TableRow,
    Text,
    ThematicBreak,
    UnorderedList
  ]

  @doc """
  Recursively searches through a list of objects or a single object to find the first
  element that satisfies the given predicate.

  Returns `nil` if no element matches.

  ## Examples

      iex> alias DocSpec.Spec
      iex> alias DocSpec.Spec.{Document, Heading, Paragraph}
      iex> doc = %Document{id: "1", children: [
      ...>   %Paragraph{id: "2", children: []},
      ...>   %Heading{id: "3", level: 1, children: []}
      ...> ]}
      iex> Spec.find_recursive(doc.children, fn
      ...>   %Heading{level: 1} -> true
      ...>   _ -> false
      ...> end)
      %Heading{id: "3", level: 1, children: []}
  """
  @spec find_recursive([object()], (object() -> boolean())) :: object() | nil
  def find_recursive([], _predicate),
    do: nil

  def find_recursive([head | tail], predicate) when is_list(tail),
    do: find_recursive(head, predicate) || find_recursive(tail, predicate)

  def find_recursive(%type{} = object, predicate) when type in @objects do
    if predicate.(object) do
      object
    else
      object |> Map.get(:children, []) |> find_recursive(predicate)
    end
  end

  @doc """
  Recursively searches through a list of objects or a single object to find the first
  element that satisfies the given predicate. Returns the default value if no element matches.

  ## Examples

      iex> alias DocSpec.Spec
      iex> alias DocSpec.Spec.{Paragraph}
      iex> paragraphs = [%Paragraph{id: "1", children: []}, %Paragraph{id: "2", children: []}]
      iex> Spec.find_recursive(paragraphs, fn _ -> false end, :not_found)
      :not_found
  """
  @spec find_recursive([object()], (object() -> boolean()), default) :: object() | default
        when default: var
  def find_recursive(elements, predicate, default),
    do: find_recursive(elements, predicate) || default
end
