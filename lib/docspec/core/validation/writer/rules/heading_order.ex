defmodule DocSpec.Core.Validation.Writer.Rules.HeadingOrder do
  @moduledoc """
  This rule validates that headings are ordered sequentially-descending,
  i.e. heading levels should only increase by one, but may decrease by any.
  """

  alias DocSpec.Core.Validation.Writer.{Severity, State}
  alias DocSpec.Spec.Heading

  use DocSpec.Core.Validation.Writer.Rule,
    severity: Severity.error(),
    rule: "heading-order",
    ruleset: "https://dequeuniversity.com/rules/axe/html",
    ruleset_version: "4.10",
    validates: [Heading]

  @impl true
  def valid?(%Heading{level: level}, %State{heading_level: last_level}),
    do: level - 1 <= last_level

  @impl true
  def update_state(state = %State{}, %Heading{level: level}),
    do: state |> State.set(:heading_level, level)
end
