defmodule DocSpec.Core.Validation.Writer.Rules.HeadingLevelValid do
  @moduledoc """
  This rule validates that a heading's level is valid according to the HTML spec (i.e. between 1 and 6).
  """

  alias DocSpec.Core.Validation.Writer.Severity
  alias DocSpec.Spec.Heading

  use DocSpec.Core.Validation.Writer.Rule,
    severity: Severity.error(),
    rule: "invalid-heading-level",
    ruleset: "https://html.spec.whatwg.org/",
    ruleset_version: "5",
    validates: [Heading]

  @impl true
  def valid?(%Heading{level: level}, _),
    do: level >= 1 and level <= 6
end
