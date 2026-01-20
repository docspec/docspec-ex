defmodule DocSpec.Core.Validation.Writer.Rules.StyleBoldInHeading do
  @moduledoc """
  This rule validates that heading is not manually styled bold.

  Underlined is covered by the NoUnderline Rule
  """

  alias DocSpec.Core.Validation.Writer.{Severity, State}
  alias DocSpec.Spec.{Heading, Link, Paragraph, Styles, Text}

  use DocSpec.Core.Validation.Writer.Rule,
    severity: Severity.warning(),
    rule: "style-bold-in-heading",
    ruleset: "https://validation.spec.docspec.io/",
    # @TODO set `ruleset_version` to a real version
    ruleset_version: "unknown",
    validates: [Paragraph, Heading, Text, Link]

  @impl true
  def update_state(state = %State{}, %Heading{}),
    do: %State{state | parent_is_heading?: true}

  @impl true
  def update_state(state = %State{}, %{children: _children}),
    do: %State{state | parent_is_heading?: false}

  @impl true
  def valid?(%{styles: %Styles{bold: bold}}, %State{parent_is_heading?: true}),
    do: not bold

  def valid?(%{styles: nil}, %State{parent_is_heading?: true}),
    do: true
end
