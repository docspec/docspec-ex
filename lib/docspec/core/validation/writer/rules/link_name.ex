defmodule DocSpec.Core.Validation.Writer.Rules.LinkName do
  @moduledoc """
  This rule validates that a link must always contain discernible text.
  """

  alias DocSpec.Core.Validation.Writer.Severity
  alias DocSpec.Spec.{Content, Link}

  use DocSpec.Core.Validation.Writer.Rule,
    severity: Severity.error(),
    rule: "link-name",
    ruleset: "https://dequeuniversity.com/rules/axe/html",
    ruleset_version: "4.10",
    validates: [Link]

  @impl true
  def valid?(resource = %Link{}, _),
    do: resource |> Content.discernible_text?()
end
