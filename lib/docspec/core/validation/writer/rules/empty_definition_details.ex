defmodule DocSpec.Core.Validation.Writer.Rules.EmptyDefinitionDetails do
  @moduledoc """
  This rule validates that definition details must always contain discernible text.
  """

  alias DocSpec.Core.Validation.Writer.Severity
  alias DocSpec.Spec.{Content, DefinitionDetails}

  use DocSpec.Core.Validation.Writer.Rule,
    severity: Severity.error(),
    rule: "empty-definition-details",
    ruleset: "https://validation.spec.docspec.io/",
    # @TODO set `ruleset_version` to a real version
    ruleset_version: "unknown",
    validates: [DefinitionDetails]

  @impl true
  def valid?(resource = %DefinitionDetails{}, _),
    do: resource |> Content.discernible_text?()
end
