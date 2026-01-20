defmodule DocSpec.Core.Util.Asset do
  @moduledoc """
  Utility functions for working with `DocSpec.Spec.Asset` structs.
  """

  alias DocSpec.Spec.Asset

  @doc """
  Converts an Asset to a data URI string.

  The data URI format is: `data:<content_type>;base64,<data>`

  ## Examples

      iex> asset = %DocSpec.Spec.Asset{
      ...>   id: "123",
      ...>   content_type: "image/png",
      ...>   data: "iVBORw0KGgo=",
      ...>   encoding: "base64"
      ...> }
      iex> DocSpec.Core.Util.Asset.to_base64(asset)
      "data:image/png;base64,iVBORw0KGgo="
  """
  @spec to_base64(Asset.t()) :: String.t()
  def to_base64(%Asset{content_type: content_type, data: data}) do
    "data:#{content_type};base64,#{data}"
  end

  @doc """
  Creates an Asset from a data URI string.

  Parses data URIs like `data:image/png;base64,iVBORw0KGgo...` and extracts
  the content type and data.

  ## Examples

      iex> DocSpec.Core.Util.Asset.from_data_uri("asset-123", "data:image/png;base64,iVBORw0KGgo=")
      %DocSpec.Spec.Asset{
        id: "asset-123",
        content_type: "image/png",
        data: "iVBORw0KGgo=",
        encoding: "base64"
      }

      iex> DocSpec.Core.Util.Asset.from_data_uri("asset-456", "data:image/jpeg;base64,/9j/4AAQ")
      %DocSpec.Spec.Asset{
        id: "asset-456",
        content_type: "image/jpeg",
        data: "/9j/4AAQ",
        encoding: "base64"
      }
  """
  @spec from_data_uri(id :: String.t(), data_uri :: String.t()) :: Asset.t()
  def from_data_uri(id, "data:" <> rest) do
    {content_type, data} =
      case String.split(rest, ";base64,", parts: 2) do
        [content_type, data] -> {content_type, data}
        _ -> {"application/octet-stream", rest}
      end

    %Asset{id: id, content_type: content_type, data: data, encoding: "base64"}
  end

  def from_data_uri(id, data) do
    %Asset{id: id, content_type: "application/octet-stream", data: data, encoding: "base64"}
  end
end
