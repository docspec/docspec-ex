defmodule DocSpec.JSON do
  @moduledoc """
  Unified JSON encoding and decoding for the DocSpec project.

  This module provides a consistent way to convert between Elixir structs/maps and JSON,
  with the following conventions:

  - **Encoding**: Converts snake_case keys to camelCase, omits fields with default values
  - **Decoding**: Converts camelCase keys to snake_case atoms

  Works with any struct in the project, including:
  - `DocSpec.Spec.*` structs (Document, Paragraph, Text, etc.)
  - `DocSpec.Core.BlockNote.Spec.*` structs
  - Any other struct with default values

  ## Examples

      # Encoding a struct to JSON
      iex> text = %DocSpec.Spec.Text{id: "123", text: "hello", styles: %DocSpec.Spec.Styles{bold: true}}
      iex> DocSpec.JSON.encode!(text)
      ~s({"id":"123","styles":{"bold":true},"text":"hello","type":"https://alpha.docspec.io/Text"})

      # Decoding JSON to a map (ready for struct constructors)
      iex> DocSpec.JSON.decode!(~s({"textColor":"#ff0000","boldText":true}))
      %{text_color: "#ff0000", bold_text: true}

      # Converting structs to encodable maps (useful for testing/inspection)
      iex> DocSpec.JSON.to_encodable(%DocSpec.Spec.Styles{bold: true, italic: false})
      %{"bold" => true}

  """

  # Fields that should always be included even if they match defaults.
  # The `type` field is the discriminator for polymorphic types.
  # The `version` field identifies the specification version.
  @always_include_fields [:type, :version]

  # ============================================================================
  # Encoding (Elixir -> JSON)
  # ============================================================================

  @doc """
  Encodes a value to a JSON string.

  For structs, this:
  - Omits fields that have their default values
  - Converts keys to camelCase
  - Recursively handles nested structs and lists

  ## Examples

      iex> DocSpec.JSON.encode(%{text_color: "#ff0000"})
      {:ok, ~s({"textColor":"#ff0000"})}

      iex> DocSpec.JSON.encode(%DocSpec.Spec.Styles{bold: true})
      {:ok, ~s({"bold":true})}

  """
  @spec encode(any(), keyword()) :: {:ok, String.t()} | {:error, Jason.EncodeError.t()}
  def encode(value, opts \\ []) do
    value
    |> to_encodable()
    |> Jason.encode(opts)
  end

  @doc """
  Encodes a value to a JSON string, raising on error.

  See `encode/2` for details.

  ## Examples

      iex> DocSpec.JSON.encode!(%{text_color: "#ff0000"})
      ~s({"textColor":"#ff0000"})

  """
  @spec encode!(any(), keyword()) :: String.t()
  def encode!(value, opts \\ []) do
    value
    |> to_encodable()
    |> Jason.encode!(opts)
  end

  @doc """
  Converts a value to an encodable map/list structure, omitting default values.

  For structs:
  - Omits fields that have their default values
  - Converts keys to camelCase strings
  - Recursively processes nested values

  For maps:
  - Converts keys to camelCase strings
  - Recursively processes nested values

  This produces minimal JSON by removing fields that match defaults.
  Use `to_map/1` if you want to keep all fields regardless of defaults.

  ## Examples

      iex> DocSpec.JSON.to_encodable(%DocSpec.Spec.Styles{bold: true, italic: false})
      %{"bold" => true}

      iex> DocSpec.JSON.to_encodable(%{text_color: "#ff0000", nested: %{font_size: 12}})
      %{"textColor" => "#ff0000", "nested" => %{"fontSize" => 12}}

      iex> DocSpec.JSON.to_encodable([%{item_id: 1}, %{item_id: 2}])
      [%{"itemId" => 1}, %{"itemId" => 2}]

  """
  @spec to_encodable(any()) :: any()
  def to_encodable(nil), do: nil

  def to_encodable(struct) when is_struct(struct) do
    # Get the default struct for comparison
    defaults = struct.__struct__.__struct__()

    struct
    |> Map.from_struct()
    |> Enum.map(fn {k, v} -> {k, to_encodable(v)} end)
    |> Enum.reject(fn {k, v} ->
      # Always include certain fields (like `type`) even if they match defaults
      if k in @always_include_fields and not is_nil(v) do
        false
      else
        default_v = to_encodable(Map.get(defaults, k))
        # Reject if value matches default OR if it's an empty map (all-default nested struct)
        v == default_v or v == %{}
      end
    end)
    |> Map.new(fn {k, v} -> {to_camel_case(k), v} end)
  end

  def to_encodable(map) when is_map(map) do
    Map.new(map, fn {k, v} -> {to_camel_case(k), to_encodable(v)} end)
  end

  def to_encodable(list) when is_list(list) do
    Enum.map(list, &to_encodable/1)
  end

  def to_encodable(other), do: other

  @doc """
  Converts a value to a map/list structure with camelCase keys, keeping all fields.

  Unlike `to_encodable/1`, this function does NOT omit default values.
  Use this when you need consistent structure for external format consumers.

  ## Examples

      iex> DocSpec.JSON.to_map(%DocSpec.Spec.Styles{bold: true, italic: false})
      %{"bold" => true, "italic" => false, "underline" => false, "strikethrough" => false, "textColor" => nil, "highlightColor" => nil}

      iex> DocSpec.JSON.to_map(%{text_color: "#ff0000"})
      %{"textColor" => "#ff0000"}

      iex> DocSpec.JSON.to_map([%{item_id: 1}])
      [%{"itemId" => 1}]

  """
  @spec to_map(any()) :: any()
  def to_map(nil), do: nil

  def to_map(struct) when is_struct(struct) do
    struct
    |> Map.from_struct()
    |> Map.new(fn {k, v} -> {to_camel_case(k), to_map(v)} end)
  end

  def to_map(map) when is_map(map) do
    Map.new(map, fn {k, v} -> {to_camel_case(k), to_map(v)} end)
  end

  def to_map(list) when is_list(list) do
    Enum.map(list, &to_map/1)
  end

  def to_map(other), do: other

  # ============================================================================
  # Decoding (JSON -> Elixir)
  # ============================================================================

  @doc """
  Decodes a JSON string to a map with snake_case atom keys.

  This is the inverse of `encode/1` - it converts camelCase JSON keys back to
  snake_case atoms suitable for passing to struct constructors like `Document.new/1`.

  ## Examples

      iex> DocSpec.JSON.decode(~s({"textColor":"#ff0000","highlightColor":null}))
      {:ok, %{text_color: "#ff0000", highlight_color: nil}}

      iex> DocSpec.JSON.decode(~s({"children":[{"type":"text"}]}))
      {:ok, %{children: [%{type: "text"}]}}

  """
  @spec decode(String.t()) :: {:ok, map()} | {:error, Jason.DecodeError.t()}
  def decode(json) when is_binary(json) do
    case Jason.decode(json) do
      {:ok, data} -> {:ok, from_decoded(data)}
      error -> error
    end
  end

  @doc """
  Decodes a JSON string to a map with snake_case atom keys, raising on error.

  See `decode/1` for details.

  ## Examples

      iex> DocSpec.JSON.decode!(~s({"textColor":"#ff0000"}))
      %{text_color: "#ff0000"}

  """
  @spec decode!(String.t()) :: map()
  def decode!(json) when is_binary(json) do
    json |> Jason.decode!() |> from_decoded()
  end

  @doc """
  Converts a decoded map/list with camelCase string keys to snake_case atom keys.

  This is useful when you've already decoded JSON and need to convert the keys.

  ## Examples

      iex> DocSpec.JSON.from_decoded(%{"textColor" => "#ff0000"})
      %{text_color: "#ff0000"}

      iex> DocSpec.JSON.from_decoded([%{"assetId" => "123"}])
      [%{asset_id: "123"}]

  """
  @spec from_decoded(any()) :: any()
  def from_decoded(map) when is_map(map) do
    Map.new(map, fn {k, v} -> {to_snake_case(k), from_decoded(v)} end)
  end

  def from_decoded(list) when is_list(list) do
    Enum.map(list, &from_decoded/1)
  end

  def from_decoded(other), do: other

  # ============================================================================
  # Key Conversion Helpers
  # ============================================================================

  @doc """
  Converts a snake_case atom or string to a camelCase string.

  ## Examples

      iex> DocSpec.JSON.to_camel_case(:text_color)
      "textColor"

      iex> DocSpec.JSON.to_camel_case("highlight_color")
      "highlightColor"

      iex> DocSpec.JSON.to_camel_case(:id)
      "id"

  """
  @spec to_camel_case(atom() | String.t()) :: String.t()
  def to_camel_case(key) when is_atom(key), do: to_camel_case(Atom.to_string(key))

  def to_camel_case(key) when is_binary(key) do
    case String.split(key, "_") do
      [first | rest] -> first <> Enum.map_join(rest, "", &String.capitalize/1)
      _ -> key
    end
  end

  @doc """
  Converts a camelCase string to a snake_case atom.

  ## Examples

      iex> DocSpec.JSON.to_snake_case("textColor")
      :text_color

      iex> DocSpec.JSON.to_snake_case("highlightColor")
      :highlight_color

      iex> DocSpec.JSON.to_snake_case("id")
      :id

  """
  @spec to_snake_case(String.t() | atom()) :: atom()
  def to_snake_case(key) when is_atom(key), do: key

  def to_snake_case(key) when is_binary(key) do
    key
    |> String.replace(~r/([a-z])([A-Z])/, "\\1_\\2")
    |> String.downcase()
    |> String.to_atom()
  end
end
