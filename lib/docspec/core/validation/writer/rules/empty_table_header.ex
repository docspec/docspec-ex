defmodule DocSpec.Core.Validation.Writer.Rules.EmptyTableHeader do
  @moduledoc """
  This rule validates that a table header must always contain discernible text.
  """

  alias DocSpec.Core.Validation.Writer.Severity
  alias DocSpec.Spec.{Content, TableHeader}

  use DocSpec.Core.Validation.Writer.Rule,
    severity: Severity.error(),
    rule: "empty-table-header",
    ruleset: "https://dequeuniversity.com/rules/axe/html",
    ruleset_version: "4.10",
    validates: [TableHeader]

  @impl true
  def valid?(resource = %TableHeader{}, _),
    do: resource |> Content.discernible_text?()
end
