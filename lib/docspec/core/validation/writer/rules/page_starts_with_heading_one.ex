defmodule DocSpec.Core.Validation.Writer.Rules.PageStartsWithHeadingOne do
  @moduledoc """
  This rule validates that a document starts with a Heading with level 1.
  It produces a validation finding on the first heading with level 1 found in the document,
  if it is not the first element in the document.

  Note: this rule will *not* produce a validation finding if the document does not contain a heading with level 1.
  """

  alias DocSpec.Core.Validation.Writer.Severity
  alias DocSpec.Spec.{Document, Heading}

  use DocSpec.Core.Validation.Writer.Rule,
    severity: Severity.warning(),
    rule: "page-starts-with-heading-one",
    ruleset: "https://validation.spec.docspec.io/",
    # @TODO set `ruleset_version` to a real version
    ruleset_version: "unknown",
    validates: [Document]

  def validate(%Document{children: children}, state = %State{}) do
    heading_one = children |> DocSpec.Spec.find_recursive(&heading_one?/1)
    first_element = children |> Enum.at(0)

    case heading_one do
      nil -> state
      ^first_element -> state
      _ -> state |> State.prepend(:findings, make_finding(heading_one.id))
    end
  end

  defp heading_one?(%Heading{level: 1}), do: true
  defp heading_one?(_), do: false
end
