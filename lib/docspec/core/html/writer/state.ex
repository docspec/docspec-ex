defmodule DocSpec.Core.HTML.Writer.State do
  @moduledoc """
  This module defines a struct that captures the state of the converter during a HTML conversion.
  """

  use DocSpec.Util.State

  alias DocSpec.Core.Util.Asset, as: AssetUtil
  alias DocSpec.Spec.Asset

  @type html_tag_or_text :: Floki.html_tag() | Floki.html_text()
  @type asset_to_uri_fn :: (Asset.t() -> String.t())

  schema do
    field :ordered_footnote_ids, %{String.t() => number()}
    field :existing_footnote_ids, [String.t()]
    field :assets, [Asset.t()]
    field :fn_asset_to_uri, asset_to_uri_fn(), default: &AssetUtil.to_base64/1
  end

  @spec asset_to_uri(state :: t(), asset :: Asset.t()) :: String.t()
  def asset_to_uri(%__MODULE__{fn_asset_to_uri: fun}, asset = %Asset{}),
    do: fun.(asset)

  @doc """
  Get current footnote number based on footnotes in state.

  ## Examples

      iex> %DocSpec.Core.HTML.Writer.State{ordered_footnote_ids: %{ "abc" => 1, "xyz" => 2 }}
      ...> |> DocSpec.Core.HTML.Writer.State.current_footnote_number()
      2
  """
  @spec current_footnote_number(t()) :: number()
  def current_footnote_number(%__MODULE__{ordered_footnote_ids: ids}),
    do: map_size(ids)

  @doc """
  Upsert new footnote to state.

  ## Examples

  When reference was encountered that refers to a valid footnote.

      iex> %DocSpec.Core.HTML.Writer.State{
      ...>   ordered_footnote_ids: %{ "abc" => 1 },
      ...>   existing_footnote_ids: ["abc", "xyz"]}
      ...> |> DocSpec.Core.HTML.Writer.State.upsert_footnote_id("xyz")
      {2, %DocSpec.Core.HTML.Writer.State{
        ordered_footnote_ids: %{"abc" => 1, "xyz" => 2},
        existing_footnote_ids: ["abc", "xyz"]}}

  When dead reference was encountered.

      iex> %DocSpec.Core.HTML.Writer.State{
      ...>   ordered_footnote_ids: %{ "abc" => 1 },
      ...>   existing_footnote_ids: ["abc", "xyz"]}
      ...> |> DocSpec.Core.HTML.Writer.State.upsert_footnote_id("def")
      {nil, %DocSpec.Core.HTML.Writer.State{
        ordered_footnote_ids: %{"abc" => 1},
        existing_footnote_ids: ["abc", "xyz"]}}


  When footnote is referenced that was referenced before

      iex> %DocSpec.Core.HTML.Writer.State{
      ...>   ordered_footnote_ids: %{ "abc" => 1, "xyz" => 2 },
      ...>   existing_footnote_ids: ["abc", "xyz"]}
      ...> |> DocSpec.Core.HTML.Writer.State.upsert_footnote_id("xyz")
      {2, %DocSpec.Core.HTML.Writer.State{
        ordered_footnote_ids: %{"abc" => 1, "xyz" => 2},
        existing_footnote_ids: ["abc", "xyz"]}}
  """
  @spec upsert_footnote_id(t(), String.t()) :: {number() | nil, t()}
  def upsert_footnote_id(state = %__MODULE__{}, id) do
    cond do
      # Footnote referenced to does not exist
      not Enum.member?(state.existing_footnote_ids, id) ->
        {nil, state}

      # Footnote is referenced to previously, so already has a number.
      Map.has_key?(state.ordered_footnote_ids, id) ->
        {Map.get(state.ordered_footnote_ids, id), state}

      true ->
        number = current_footnote_number(state) + 1
        {number, %{state | ordered_footnote_ids: Map.put(state.ordered_footnote_ids, id, number)}}
    end
  end

  @doc """
  Get asset by id from state.

  ## Examples

      iex> alias DocSpec.Core.HTML.Writer.State
      iex> alias DocSpec.Spec.Asset
      iex> state = %State{assets: [%Asset{id: "123"}]}
      iex> state |> State.find_asset("123")
      %Asset{id: "123"}
      iex> state |> State.find_asset("456")
      nil

  """
  @spec find_asset(state :: t(), id :: String.t()) :: Asset.t() | nil
  def find_asset(%__MODULE__{assets: assets}, id) do
    assets |> Enum.find(&(&1.id == id))
  end
end
