defmodule DocSpec.Core.HTML.Writer.Head do
  @moduledoc false

  alias DocSpec.Core.HTML.Writer.SimpleForm
  alias DocSpec.Spec.{Author, Document, DocumentMeta}

  @spec element(Document.t()) :: Floki.html_node()

  @fallback_title "Document"

  @doc """
  Generates head-element based on document.

  ## Examples

      iex> alias DocSpec.Spec.{Author, Document, DocumentMeta}
      iex> meta = %DocumentMeta{
      ...>   title: "Example Title",
      ...>   authors: [%Author{name: "Example Creator"}],
      ...>   description: "Example Description"
      ...> }
      iex> DocSpec.Core.HTML.Writer.Head.element(%Document{metadata: meta})
      {"head", [], [
        {"style", [], [
          ".lst-circle { list-style-type: circle; }",
          ".lst-square { list-style-type: square; }",
          "section.footnotes { border-top: 1px solid; }"]},
        {"meta", [{"name", "author"}, {"content", "Example Creator"}], []},
        {"meta", [{"name", "description"}, {"content", "Example Description"}], []},
        {"title", [], ["Example Title"]}]}
  """
  def element(%Document{metadata: metadata}) do
    meta_elements = metadata_to_meta_elements(metadata)

    meta_elements_with_title =
      if Enum.any?(meta_elements, &match?({"title", _, _}, &1)) do
        meta_elements
      else
        [title_tag(@fallback_title) | meta_elements]
      end

    "head"
    |> SimpleForm.tag()
    |> SimpleForm.put_children(meta_elements_with_title)
    |> SimpleForm.prepend_child(
      "style"
      |> SimpleForm.tag()
      |> SimpleForm.put_children([
        ".lst-circle { list-style-type: circle; }",
        ".lst-square { list-style-type: square; }",
        "section.footnotes { border-top: 1px solid; }"
      ])
    )
  end

  @spec metadata_to_meta_elements(DocumentMeta.t() | nil) :: [Floki.html_node()]
  defp metadata_to_meta_elements(nil), do: []

  defp metadata_to_meta_elements(%DocumentMeta{
         title: title,
         authors: authors,
         description: description
       }) do
    author_meta =
      case authors do
        [%Author{name: name} | _] when is_binary(name) and name != "" ->
          [meta_tag("author", name)]

        _ ->
          []
      end

    description_meta =
      if is_binary(description) and description != "" do
        [meta_tag("description", description)]
      else
        []
      end

    title_meta =
      if is_binary(title) and title != "" do
        [title_tag(title)]
      else
        []
      end

    author_meta ++ description_meta ++ title_meta
  end

  @spec title_tag(String.t()) :: Floki.html_tag()
  defp title_tag(content), do: {"title", [], [content]}

  @spec meta_tag(String.t(), String.t()) :: Floki.html_tag()
  defp meta_tag(name, content),
    do: {"meta", [{"name", name}, {"content", content}], []}
end
