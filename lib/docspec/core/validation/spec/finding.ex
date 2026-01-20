defmodule DocSpec.Core.Validation.Spec.Finding do
  @moduledoc """
  Represents a validation finding for a document resource.

  ## Examples

      iex> %DocSpec.Core.Validation.Spec.Finding{
      ...>   resource_id: "550e8400-e29b-41d4-a716-446655440000",
      ...>   severity: :error,
      ...>   rule: "empty-heading",
      ...>   ruleset: "https://wcag.nl/",
      ...>   ruleset_version: "1.0"
      ...> }
      %DocSpec.Core.Validation.Spec.Finding{
        type: "https://validation.spec.docspec.io/Finding",
        resource_id: "550e8400-e29b-41d4-a716-446655440000",
        severity: :error,
        rule: "empty-heading",
        ruleset: "https://wcag.nl/",
        ruleset_version: "1.0"
      }

  """

  use TypedStruct

  @type severity() :: :error | :warning | :notice

  @resource_type "https://validation.spec.docspec.io/Finding"

  @doc """
  Returns the resource type URI for validation findings.
  """
  @spec resource_type() :: String.t()
  def resource_type, do: @resource_type

  typedstruct enforce: true do
    field :type, String.t(), default: @resource_type
    field :resource_id, String.t()
    field :severity, severity()
    field :rule, String.t()
    field :ruleset, String.t()
    field :ruleset_version, String.t()
  end

  @doc """
  Creates a new Finding struct from a map of attributes.

  Returns `{:ok, finding}` on success, or `{:error, reason}` on failure.

  ## Examples

      iex> DocSpec.Core.Validation.Spec.Finding.new(%{
      ...>   resource_id: "550e8400-e29b-41d4-a716-446655440000",
      ...>   severity: :warning,
      ...>   rule: "no-underline",
      ...>   ruleset: "https://wcag.nl/",
      ...>   ruleset_version: "1.0"
      ...> })
      {:ok, %DocSpec.Core.Validation.Spec.Finding{
        type: "https://validation.spec.docspec.io/Finding",
        resource_id: "550e8400-e29b-41d4-a716-446655440000",
        severity: :warning,
        rule: "no-underline",
        ruleset: "https://wcag.nl/",
        ruleset_version: "1.0"
      }}

      iex> DocSpec.Core.Validation.Spec.Finding.new(%{resource_id: "test"})
      {:error, "Missing required fields: severity, rule, ruleset, ruleset_version"}

  """
  @spec new(map()) :: {:ok, t()} | {:error, String.t()}
  def new(attrs) when is_map(attrs) do
    required = [:resource_id, :severity, :rule, :ruleset, :ruleset_version]
    missing = Enum.filter(required, fn key -> not Map.has_key?(attrs, key) end)

    if missing == [] do
      {:ok,
       %__MODULE__{
         type: Map.get(attrs, :type, @resource_type),
         resource_id: Map.fetch!(attrs, :resource_id),
         severity: Map.fetch!(attrs, :severity),
         rule: Map.fetch!(attrs, :rule),
         ruleset: Map.fetch!(attrs, :ruleset),
         ruleset_version: Map.fetch!(attrs, :ruleset_version)
       }}
    else
      {:error, "Missing required fields: #{Enum.join(missing, ", ")}"}
    end
  end

  @doc """
  Creates a new Finding struct from a map of attributes.

  Raises on invalid input.

  ## Examples

      iex> DocSpec.Core.Validation.Spec.Finding.new!(%{
      ...>   resource_id: "550e8400-e29b-41d4-a716-446655440000",
      ...>   severity: :notice,
      ...>   rule: "style-bold-in-heading",
      ...>   ruleset: "https://wcag.nl/",
      ...>   ruleset_version: "1.0"
      ...> })
      %DocSpec.Core.Validation.Spec.Finding{
        type: "https://validation.spec.docspec.io/Finding",
        resource_id: "550e8400-e29b-41d4-a716-446655440000",
        severity: :notice,
        rule: "style-bold-in-heading",
        ruleset: "https://wcag.nl/",
        ruleset_version: "1.0"
      }

  """
  @spec new!(map()) :: t()
  def new!(attrs) when is_map(attrs) do
    case new(attrs) do
      {:ok, finding} -> finding
      {:error, reason} -> raise ArgumentError, reason
    end
  end
end
