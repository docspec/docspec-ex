defmodule DocSpec.Core.Validation.Writer.Rules.PageHasHeadingOne do
  @moduledoc """
  This rule validates that a document has at least one heading level 1.
  """

  alias DocSpec.Core.Validation.Writer.Severity
  alias DocSpec.Spec.{Document, Heading}

  use DocSpec.Core.Validation.Writer.Rule,
    severity: Severity.error(),
    rule: "page-has-heading-one",
    ruleset: "https://dequeuniversity.com/rules/axe/html",
    ruleset_version: "4.10",
    validates: [Document]

  @impl true
  def valid?(%Document{children: children}, _),
    do: DocSpec.Spec.find_recursive(children, &heading_one?/1) != nil

  defp heading_one?(%Heading{level: 1}), do: true
  defp heading_one?(_), do: false
end
