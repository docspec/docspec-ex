defmodule DocSpec.Core.DOCX.Reader.State do
  @moduledoc """
  This module defines a struct that captures the state of the converter during a Docx conversion.
  """

  alias DocSpec.Core.DOCX.Reader.AST.RunProperties

  alias DocSpec.Spec.{
    BlockQuotation,
    DefinitionList,
    Heading,
    OrderedList,
    Paragraph,
    Preformatted,
    Table,
    UnorderedList
  }

  use DocSpec.Util.State

  @typedoc """
  Block elements that can be extracted from nested contexts (e.g., text boxes inside paragraphs).
  """
  @type block() ::
          BlockQuotation.t()
          | DefinitionList.t()
          | Heading.t()
          | OrderedList.t()
          | Paragraph.t()
          | Preformatted.t()
          | Table.t()
          | UnorderedList.t()

  schema do
    field :has_title, boolean(), default: false
    field :hyperlink_target, String.t() | nil
    field :styling, RunProperties.t(), default: RunProperties.parse(nil, nil)
    field :assets, %{String.t() => String.t()}
    field :numbering_id, String.t() | nil

    # Root list in this context is a list with ilvl = 0
    field :last_root_list_count, number(), default: 0

    # Tracks whether we're inside a paragraph context (for handling nested paragraphs in text boxes)
    field :paragraph_mode?, boolean(), default: false

    # Block elements extracted from nested contexts to be inserted as siblings
    field :extracted_paragraphs, [block()], default: []
  end

  @doc """
  Upserts the existence of an asset based on it's relative path.

  ## Examples

      iex> alias DocSpec.Core.DOCX.Reader.State
      iex> {uuid, state} = State.upsert_asset(%State{}, "media/image.png")
      iex> %{"media/image.png" => ^uuid} = state.assets

      iex> alias DocSpec.Core.DOCX.Reader.State
      iex> {"xyz", state} = State.upsert_asset(%State{assets: %{"media/image.png" => "xyz"}}, "media/image.png")
      iex> %{"media/image.png" => "xyz"} = state.assets
  """
  @spec upsert_asset(state :: t(), relative_path :: String.t()) :: {String.t(), t()}
  def upsert_asset(state = %__MODULE__{assets: assets}, relative_path) do
    if Map.has_key?(assets, relative_path) do
      {Map.get(assets, relative_path), state}
    else
      id = Ecto.UUID.generate()
      {id, %{state | assets: assets |> Map.put(relative_path, id)}}
    end
  end
end
