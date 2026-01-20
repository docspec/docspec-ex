defmodule DocSpec.Util.StringFormat do
  @moduledoc """
  Checks if is uri or path
  """

  @doc """
  Converts a map or struct to a map with different keys.

  ## Examples

  With string values:

      iex> DocSpec.Util.StringFormat.uri?("https://example.com/123")
      true
      iex> DocSpec.Util.StringFormat.uri?("media/image.png")
      false
      iex> DocSpec.Util.StringFormat.uri?("ftp://example.com/123")
      true

  Or with parsed URI's:

      iex> DocSpec.Util.StringFormat.uri?(%URI{path: "media/image.png"})
      false
      iex> DocSpec.Util.StringFormat.uri?(%URI{scheme: "http", host: "example.com", path: "/media/image.png"})
      true
  """

  @spec uri?(String.t()) :: boolean()
  @spec uri?(URI.t()) :: boolean()

  def uri?(value) when is_binary(value),
    do: value |> URI.parse() |> uri?()

  def uri?(%URI{scheme: scheme}),
    do: not is_nil(scheme)
end
