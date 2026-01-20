defmodule DocSpec.Core.Validation.Writer.Rules.PageHasMultipleHeadingOne do
  @moduledoc """
  This rule validates that the document has only one Heading with level 1.
  """

  alias DocSpec.Core.Validation.Writer.{Severity, State}
  alias DocSpec.Spec.Heading

  use DocSpec.Core.Validation.Writer.Rule,
    severity: Severity.warning(),
    rule: "page-has-multiple-heading-one",
    ruleset: "https://validation.spec.docspec.io/",
    # @TODO set `ruleset_version` to a real version
    ruleset_version: "unknown",
    validates: [Heading]

  @impl true
  def valid?(%Heading{level: 1}, %State{encountered_heading_1?: true}),
    do: false

  @impl true
  def update_state(state = %State{}, %Heading{level: 1}),
    do: state |> State.set(:encountered_heading_1?, true)
end
