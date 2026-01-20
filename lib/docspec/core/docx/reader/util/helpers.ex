defmodule DocSpec.Core.DOCX.Reader.Util.Helpers do
  @moduledoc """
  This module defines utility functions for the DocSpec spec objects.
  """

  alias DocSpec.Spec.{DefinitionList, Link, OrderedList, Preformatted, Text, UnorderedList}

  @doc """
  Adds all resources from the second list to the first list, using `add/2` to merge them where possible.

  ## Examples

      iex> import DocSpec.Core.DOCX.Reader.Util.Helpers
      iex> alias DocSpec.Spec.{Styles, Text}
      iex> bold = %Styles{bold: true}
      iex> italic = %Styles{italic: true}
      iex> existing_resources = [
      ...>   %Text{text: " ", styles: bold},
      ...>   %Text{text: "message:", styles: italic}
      ...> ]
      iex> new_resources = [
      ...>   %Text{text: " World", styles: bold},
      ...>   %Text{text: "Hello", styles: bold}
      ...> ]
      iex> [first, second] = add_all(existing_resources, new_resources)
      iex> first.text
      " Hello World"
      iex> first.styles.bold
      true
      iex> second.text
      "message:"

      iex> import DocSpec.Core.DOCX.Reader.Util.Helpers
      iex> alias DocSpec.Spec.{Styles, Text}
      iex> bold = %Styles{bold: true}
      iex> italic = %Styles{italic: true}
      iex> new_resources = [
      ...>   %Text{text: "Hello", styles: bold},
      ...>   %Text{text: "World", styles: italic}
      ...> ]
      iex> [first, second] = add_all([], new_resources)
      iex> first.text
      "Hello"
      iex> first.styles.bold
      true
      iex> second.text
      "World"
      iex> second.styles.italic
      true
  """
  @spec add_all([struct()], [struct()]) :: [struct()]
  def add_all(resources, []),
    do: resources

  def add_all(resources, [x | xs]) when is_list(resources),
    do: resources |> add_all(xs) |> add(x)

  @doc """
  Adds a resource to the list of resources. If possible, merges it with the head of the list using `merge/2`.
  Ensures that the added resource has an ID by calling `add_id/1` if necessary.

  ## Examples

  Adding a resource without an ID to an empty list:

      iex> import DocSpec.Core.DOCX.Reader.Util.Helpers
      iex> alias DocSpec.Spec.{Styles, Text}
      iex> bold = %Styles{bold: true}
      iex> [result] = add([], %Text{text: "Hello", styles: bold, id: nil})
      iex> result.text
      "Hello"
      iex> result.styles.bold
      true
      iex> Ecto.UUID.cast(result.id)
      {:ok, result.id}

  Adding a resource that can be merged with the head of the list:

      iex> import DocSpec.Core.DOCX.Reader.Util.Helpers
      iex> alias DocSpec.Spec.{Styles, Text}
      iex> bold = %Styles{bold: true}
      iex> res1 = %Text{id: "1", text: "Hello", styles: bold}
      iex> res2 = %Text{id: "2", text: " World", styles: bold}
      iex> [result] = add([res1], res2)
      iex> result.text
      "Hello World"
      iex> result.id
      "1"

  Adding a resource that cannot be merged:

      iex> import DocSpec.Core.DOCX.Reader.Util.Helpers
      iex> alias DocSpec.Spec.{Styles, Text}
      iex> bold = %Styles{bold: true}
      iex> italic = %Styles{italic: true}
      iex> res1 = %Text{id: "1", text: "Hello", styles: bold}
      iex> res2 = %Text{id: "2", text: " World", styles: italic}
      iex> add([res1], res2)
      [res2, res1]
  """
  # @spec add([struct()], struct()) :: [struct()]
  def add(resources, new_resource = %{id: nil})
      when is_list(resources) and is_struct(new_resource),
      do: resources |> add(new_resource |> add_id())

  def add(
        [previous = %Link{purpose: purpose, uri: uri} | resources],
        new_resource = %Link{purpose: purpose, uri: uri}
      ) do
    if same_styles?(previous, new_resource) do
      [%{previous | text: previous.text <> new_resource.text} | resources]
    else
      [new_resource, previous | resources]
    end
  end

  def add([previous = %Text{} | resources], new_resource = %Text{}) do
    if same_styles?(previous, new_resource) do
      [%{previous | text: previous.text <> new_resource.text} | resources]
    else
      [new_resource, previous | resources]
    end
  end

  def add([previous = %Preformatted{} | resources], new = %Preformatted{}) do
    [previous |> add_child(%Text{text: "\n"}) |> add_children(new.children) | resources]
  end

  def add([previous = %DefinitionList{} | resources], new = %DefinitionList{}) do
    [previous |> add_children(new.children) | resources]
  end

  def add(
        [previous = %OrderedList{style_type: type} | resources],
        new = %OrderedList{style_type: type}
      ) do
    [previous |> add_children(new.children) | resources]
  end

  def add(
        [previous = %UnorderedList{style_type: type} | resources],
        new = %UnorderedList{style_type: type}
      ) do
    [previous |> add_children(new.children) | resources]
  end

  def add([], new_resource) when is_struct(new_resource),
    do: [new_resource]

  def add(resources, new_resource) when is_struct(new_resource),
    do: [new_resource | resources]

  @doc """
  Adds a child to the resource's list of children.

  ## Examples

  Adding a child to a resource without children:

      iex> import DocSpec.Core.DOCX.Reader.Util.Helpers
      iex> alias DocSpec.Spec.{Paragraph, Styles, Text}
      iex> bold = %Styles{bold: true}
      iex> resource = %Paragraph{children: []}
      iex> child = %Text{styles: bold, text: "Hello World"}
      iex> result = add_child(resource, child)
      iex> [text_child] = result.children
      iex> text_child.text
      "Hello World"
      iex> text_child.styles.bold
      true
      iex> is_binary(text_child.id)
      true

  Adding a child to a resource with matching text children, effectively merging:

      iex> import DocSpec.Core.DOCX.Reader.Util.Helpers
      iex> alias DocSpec.Spec.{Paragraph, Styles, Text}
      iex> bold = %Styles{bold: true}
      iex> resource = %Paragraph{children: [%Text{id: "abc", styles: bold, text: "Hello"}]}
      iex> child = %Text{styles: bold, text: " World"}
      iex> result = add_child(resource, child)
      iex> [merged] = result.children
      iex> merged.text
      "Hello World"
      iex> merged.id
      "abc"

  Adding a child to a resource with children:

      iex> import DocSpec.Core.DOCX.Reader.Util.Helpers
      iex> alias DocSpec.Spec.{Paragraph, Styles, Text}
      iex> bold = %Styles{bold: true}
      iex> italic = %Styles{italic: true}
      iex> first_text = %Text{id: "abc", styles: bold, text: "Hello"}
      iex> second_text = %Text{id: "xyz", styles: italic, text: " World"}
      iex> resource = %Paragraph{children: [first_text]}
      iex> add_child(resource, second_text)
      %Paragraph{children: [second_text, first_text]}

  """
  # @spec add_child(resource, child :: struct()) :: resource
  #      when resource: %{children: [struct()]}
  def add_child(resource = %{children: children}, child) do
    %{resource | children: children |> add(child)}
  end

  @doc """
  Adds multiple children to the resource's list of children.

  ## Examples

  Adding multiple children to a resource without children:

      iex> import DocSpec.Core.DOCX.Reader.Util.Helpers
      iex> alias DocSpec.Spec.{Paragraph, Styles, Text}
      iex> bold = %Styles{bold: true}
      iex> italic = %Styles{italic: true}
      iex> resource = %Paragraph{children: []}
      iex> children = [
      ...>   %Text{styles: bold, text: "Hello"},
      ...>   %Text{styles: italic, text: " World"}
      ...> ]
      iex> result = add_children(resource, children)
      iex> [first, second] = result.children
      iex> first.styles.bold
      true
      iex> second.styles.italic
      true
      iex> is_binary(first.id) and is_binary(second.id)
      true

  Adding multiple children to a resource with children, with merging:

      iex> import DocSpec.Core.DOCX.Reader.Util.Helpers
      iex> alias DocSpec.Spec.{Paragraph, Styles, Text}
      iex> bold = %Styles{bold: true}
      iex> first_text = %Text{id: "abc", styles: bold, text: "Hello"}
      iex> second_text = %Text{id: "xyz", styles: bold, text: " World"}
      iex> resource = %Paragraph{children: [first_text]}
      iex> result = add_children(resource, [second_text])
      iex> [merged] = result.children
      iex> merged.text
      "Hello World"
      iex> merged.id
      "abc"
  """
  def add_children(resource = %{children: children}, new_children) do
    %{resource | children: children |> add_all(new_children)}
  end

  @doc """
  Assigns a new unique identifier (UUID) to the resource if it doesn't already have one.
  If the resource already has an `id`, it is returned unchanged.

  ## Examples

  When the resource doesn't have an `id`:

      iex> import DocSpec.Core.DOCX.Reader.Util.Helpers
      iex> %{name: "test", id: id} = add_id(%{name: "test", id: nil})
      iex> Ecto.UUID.cast(id)
      {:ok, id}

  When the resource already has an `id`:

      iex> import DocSpec.Core.DOCX.Reader.Util.Helpers
      iex> existing_id = Ecto.UUID.generate()
      iex> resource = %{name: "test", id: existing_id}
      iex> add_id(resource)
      %{name: "test", id: existing_id}
  """
  @spec add_id(resource) :: resource when resource: struct()
  @spec add_id(resource :: map()) :: struct() | map()
  def add_id(resource = %{id: nil}),
    do: resource |> Map.put(:id, new_id())

  def add_id(resource),
    do: resource

  @doc """
  Generates a new unique identifier (UUID) as a string.

  ## Examples

      iex> import DocSpec.Core.DOCX.Reader.Util.Helpers
      iex> id = new_id()
      iex> Ecto.UUID.cast(id)
      {:ok, id}
  """
  @spec new_id :: String.t()
  def new_id, do: Ecto.UUID.generate()

  @spec same_styles?(Text.t(), Text.t()) :: boolean()
  defp same_styles?(a = %Text{}, b = %Text{}),
    do: a.styles == b.styles

  @spec same_styles?(Link.t(), Link.t()) :: boolean()
  defp same_styles?(a = %Link{}, b = %Link{}),
    do: a.styles == b.styles
end
