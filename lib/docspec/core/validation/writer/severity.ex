defmodule DocSpec.Core.Validation.Writer.Severity do
  @moduledoc """
  Severity levels for validation rules.
  """
  @type t :: :error | :warning | :notice

  def values, do: [:error, :warning, :notice]

  @spec error() :: :error
  def error, do: :error

  @spec warning() :: :warning
  def warning, do: :warning

  @spec notice() :: :notice
  def notice, do: :notice
end
