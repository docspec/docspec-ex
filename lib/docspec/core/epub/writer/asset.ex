defmodule DocSpec.Core.EPUB.Writer.Asset do
  @moduledoc """
  Logic for including assets in EPUB.
  """

  alias DocSpec.Spec.Asset

  @spec path(asset :: Asset.t(), :from_root | :from_doc | :from_package) :: String.t()
  def path(%Asset{id: id}, :from_root),
    do: "OEBPS/assets/#{id}"

  def path(%Asset{id: id}, :from_doc),
    do: "../assets/#{id}"

  def path(%Asset{id: id}, :from_package),
    do: "assets/#{id}"
end
