defmodule DocSpec.Core.Validation.Writer.Rules.DefinitionListHasDefinitionTerm do
  @moduledoc """
  This rule validates that the a definition list has at least one definition term.
  """

  alias DocSpec.Core.Validation.Writer.Severity
  alias DocSpec.Spec.{DefinitionList, DefinitionTerm}

  use DocSpec.Core.Validation.Writer.Rule,
    severity: Severity.error(),
    rule: "definition-list-has-definition-term",
    ruleset: "https://validation.spec.docspec.io/",
    # @TODO set `ruleset_version` to a real version
    ruleset_version: "unknown",
    validates: [DefinitionList]

  def valid?(definition_list = %DefinitionList{}, _),
    do: definition_list |> has_definition_term?()

  @spec has_definition_term?(DocSpec.Spec.object()) :: boolean()
  def has_definition_term?(%DefinitionTerm{}), do: true

  def has_definition_term?(%{children: children}),
    do: children |> Enum.any?(&has_definition_term?/1)

  def has_definition_term?(_), do: false
end
