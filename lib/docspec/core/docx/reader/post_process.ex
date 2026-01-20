defmodule DocSpec.Core.DOCX.Reader.PostProcess do
  @moduledoc """
  This module performs post-processing on the intermediate result of a Docx conversion
  to a DocSpec Spec document with `DocSpec.Core.DOCX.Reader.Convert`.

  This post-processing essentially does the following:
  - Recursively reverse the order of the children of every spec object in the document.
    This is done because `DocSpec.Core.DOCX.Reader.Convert` accumulates all resources in reverse order,
    as Elixir implements lists as linked lists and prepending to such a list is O(1),
    while appending to a linked list is O(n).
  - If the Docx document had a Title element, increment the level of every heading in the document by 1.
    Title elements are converted to a `Heading` with level 0, so in order to result in a valid DocSpec document,
    if a document had a title heading, all headings must be incremented by 1.
  """

  alias DocSpec.Core.DOCX.Reader
  alias DocSpec.Core.DOCX.Reader.{Files.ContentTypes, State}
  alias DocSpec.Spec.{Asset, Document, Heading}

  @type conversion() :: {[struct()], State.t()}

  @spec process(Document.t(), State.t(), Reader.t()) :: Document.t()
  @spec process(Document.t(), State.t()) :: Document.t()

  def process(document = %Document{}, state = %State{}, docx = %Reader{}) do
    document
    |> process({[], state})
    |> elem(0)
    |> hd()
    |> add_assets(state, docx)
  end

  @spec add_assets(Document.t(), State.t(), Reader.t()) :: Document.t()
  defp add_assets(document = %Document{}, %State{assets: assets}, docx = %Reader{}) do
    %{document | assets: assets |> Enum.map(&read_asset!(&1, docx))}
  end

  @spec read_asset!({String.t(), String.t()}, docx :: Reader.t()) :: Asset.t()
  defp read_asset!({relative_path, id}, docx = %Reader{}) do
    path_relative_to_document_xml =
      docx.document.path
      |> Path.dirname()
      |> Path.join(relative_path)
      |> Path.relative_to(docx.files.dir)

    %Asset{
      id: id,
      data:
        docx.document.path
        |> Path.dirname()
        |> Path.join(relative_path)
        |> File.read!()
        |> Base.encode64(),
      encoding: :base64,
      content_type:
        docx.files.types
        |> ContentTypes.type("/" |> Path.join(path_relative_to_document_xml))
    }
  end

  # -----------------------------------------------------------------------------------------------

  @spec process(struct() | [struct()], conversion()) :: conversion()
  def process([], acc), do: acc
  def process([head | tail], acc), do: process(tail, process(head, acc))

  # -----------------------------------------------------------------------------------------------

  def process(heading = %Heading{}, {resources, state = %State{}}) when state.has_title do
    {new_children, state} = heading.children |> process({[], state})
    new_resource = %Heading{heading | level: heading.level + 1, children: new_children}
    {resources |> add(new_resource), state}
  end

  # -----------------------------------------------------------------------------------------------

  def process(resource = %{children: children}, {resources, state}) do
    {new_children, state} = children |> process({[], state})
    new_resource = resource |> Map.put(:children, new_children)
    {resources |> add(new_resource), state}
  end

  def process(resource, {resources, state}),
    do: {resources |> add(resource), state}

  # -----------------------------------------------------------------------------------------------

  defp add(resources, resource) when is_list(resources) and is_struct(resource) do
    [resource | resources]
  end
end
