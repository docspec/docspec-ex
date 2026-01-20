defmodule DocSpec.Core.Validation.Writer.Rules.NoUnderline do
  @moduledoc """
  This rule validates that the style underline was not used on a Text.
  """

  alias DocSpec.Core.Validation.Writer.Severity
  alias DocSpec.Spec.{Link, Styles, Text}

  use DocSpec.Core.Validation.Writer.Rule,
    severity: Severity.warning(),
    rule: "no-underline",
    ruleset: "https://validation.spec.docspec.io/",
    # @TODO set `ruleset_version` to a real version
    ruleset_version: "unknown",
    validates: [Link, Text]

  @impl true
  def valid?(%{styles: %Styles{underline: underline}}, _),
    do: not underline

  def valid?(%{styles: nil}, _),
    do: true
end
