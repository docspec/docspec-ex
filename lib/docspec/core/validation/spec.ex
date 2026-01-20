defmodule DocSpec.Core.Validation.Spec do
  @moduledoc """
  This module defines the DocSpec Validation Specification types.
  """

  alias DocSpec.Core.Validation.Spec.Finding

  @doc """
  Returns the version of the validation spec that this library implements.
  """
  @version "3.0.135"
  @spec version() :: String.t()
  def version, do: @version

  @type object :: Finding.t()

  @objects [Finding]

  @doc """
  Returns all object types in the validation spec.
  """
  @spec objects() :: [module()]
  def objects, do: @objects

  @type type :: :finding

  @types %{
    finding: "https://validation.spec.docspec.io/Finding"
  }

  @doc """
  Returns the URI for a given type.
  """
  @spec type_uri(type()) :: String.t()
  def type_uri(type), do: Map.fetch!(@types, type)
end
