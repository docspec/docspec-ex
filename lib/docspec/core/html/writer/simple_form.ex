defmodule DocSpec.Core.HTML.Writer.SimpleForm do
  @moduledoc """
  Module for HTML (SimpleForm) operations
  """

  @spec reverse(Floki.html_tag()) :: Floki.html_tag()
  @spec reverse(Floki.html_node()) :: Floki.html_node()
  @spec reverse([Floki.html_node()]) :: Floki.html_node()

  def reverse({tag_name, attrs, children}),
    do: {tag_name, attrs, children |> reverse()}

  def reverse(list) when is_list(list),
    do: list |> Enum.map(&reverse/1) |> Enum.reverse()

  def reverse(x),
    do: x

  @doc """
  Append attributes to existing tag.

  ## Examples

      iex> { "p", [{"class", "xyz"}], ["Some Text"]}
      ...> |> DocSpec.Core.HTML.Writer.SimpleForm.append_children([{"span", [], ["Other text"]}])
      {"p", [{"class", "xyz"}], ["Some Text", {"span", [], ["Other text"]}]}
  """

  @spec put_attributes(node :: Floki.html_tag(), attributes :: [Floki.html_attribute()]) ::
          Floki.html_tag()

  def put_attributes({tag_name, _, children}, new_attributes),
    do: {tag_name, new_attributes, children}

  @doc """
  Append attributes to existing tag.

  ## Examples

      iex> { "p", [{"class", "xyz"}], ["Some Text"]}
      ...> |> DocSpec.Core.HTML.Writer.SimpleForm.append_children([{"span", [], ["Other text"]}])
      {"p", [{"class", "xyz"}], ["Some Text", {"span", [], ["Other text"]}]}
  """

  @spec append_attributes(node :: Floki.html_tag(), new_attributes :: [Floki.html_attribute()]) ::
          Floki.html_tag()

  def append_attributes(node = {_, attributes, _}, new_attributes),
    do: node |> put_attributes(attributes ++ new_attributes)

  @doc """
  Put children inside existing tag.

  ## Examples

      iex> { "p", [{"class", "xyz"}], ["Some Text"]}
      ...> |> DocSpec.Core.HTML.Writer.SimpleForm.put_children([{"span", [], ["Other text"]}])
      {"p", [{"class", "xyz"}], [{"span", [], ["Other text"]}]}
  """

  @spec put_children(node :: Floki.html_tag(), children :: [Floki.html_node()]) ::
          Floki.html_tag()

  def put_children({tag_name, attributes, _children}, children),
    do: {tag_name, attributes, children}

  @doc """
  Append children to existing tag.

  ## Examples

      iex> { "p", [{"class", "xyz"}], ["Some Text"]}
      ...> |> DocSpec.Core.HTML.Writer.SimpleForm.append_children([{"span", [], ["Other text"]}])
      {"p", [{"class", "xyz"}], ["Some Text", {"span", [], ["Other text"]}]}
  """

  @spec append_children(node :: Floki.html_tag(), new_children :: [Floki.html_node()]) ::
          Floki.html_tag()

  def append_children(node = {_, _, children}, new_children),
    do: node |> put_children(children ++ new_children)

  @doc """
  Append child to existing tag.

  ## Examples

      iex> { "p", [{"class", "xyz"}], ["Some Text"]}
      ...> |> DocSpec.Core.HTML.Writer.SimpleForm.append_child({"span", [], ["Other text"]})
      {"p", [{"class", "xyz"}], ["Some Text", {"span", [], ["Other text"]}]}
  """

  @spec append_child(node :: Floki.html_tag(), new_child :: Floki.html_node()) ::
          Floki.html_tag()

  def append_child(node, new_child),
    do: node |> append_children([new_child])

  @spec prepend_child(node :: Floki.html_tag(), new_child :: Floki.html_node()) ::
          Floki.html_tag()

  @doc """
  Append child to existing tag.

  ## Examples

      iex> { "p", [{"class", "xyz"}], ["Some Text"]}
      ...> |> DocSpec.Core.HTML.Writer.SimpleForm.append_child({"span", [], ["Other text"]})
      {"p", [{"class", "xyz"}], ["Some Text", {"span", [], ["Other text"]}]}
  """
  def prepend_child(node = {_, _, children}, new_child),
    do: node |> put_children([new_child | children])

  @doc """
  Create a new node with tag_name, attributes and children

  ## Examples

      iex> DocSpec.Core.HTML.Writer.SimpleForm.tag("p", [{"class", "xyz"}], ["Some Text"])
      {"p", [{"class", "xyz"}], ["Some Text"]}

      iex> DocSpec.Core.HTML.Writer.SimpleForm.tag("p", [{"class", "xyz"}])
      {"p", [{"class", "xyz"}], []}

      iex> DocSpec.Core.HTML.Writer.SimpleForm.tag("p")
      {"p", [], []}

  """

  @spec tag(String.t(), [Floki.html_attribute()], [Floki.html_node()]) :: Floki.html_tag()

  def tag(tag_name, attributes \\ [], children \\ []), do: {tag_name, attributes, children}
end
