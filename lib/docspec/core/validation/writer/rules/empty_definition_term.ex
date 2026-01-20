defmodule DocSpec.Core.Validation.Writer.Rules.EmptyDefinitionTerm do
  @moduledoc """
  This rule validates that a definition term must always contain discernible text.
  """

  alias DocSpec.Core.Validation.Writer.Severity
  alias DocSpec.Spec.{Content, DefinitionTerm}

  use DocSpec.Core.Validation.Writer.Rule,
    severity: Severity.error(),
    rule: "empty-definition-term",
    ruleset: "https://validation.spec.docspec.io/",
    # @TODO set `ruleset_version` to a real version
    ruleset_version: "unknown",
    validates: [DefinitionTerm]

  @impl true
  def valid?(resource = %DefinitionTerm{}, _),
    do: resource |> Content.discernible_text?()
end
