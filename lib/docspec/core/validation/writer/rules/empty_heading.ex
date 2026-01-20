defmodule DocSpec.Core.Validation.Writer.Rules.EmptyHeading do
  @moduledoc """
  This rule validates that a heading must always contain discernible text.
  """

  alias DocSpec.Core.Validation.Writer.Severity
  alias DocSpec.Spec.{Content, Heading}

  use DocSpec.Core.Validation.Writer.Rule,
    severity: Severity.error(),
    rule: "empty-heading",
    ruleset: "https://dequeuniversity.com/rules/axe/html",
    ruleset_version: "4.10",
    validates: [Heading]

  @impl true
  def valid?(resource = %Heading{}, _),
    do: resource |> Content.discernible_text?()
end
