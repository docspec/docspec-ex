defmodule DocSpec.Core.Validation.Writer.Rules.TableNeedsMultipleRows do
  @moduledoc """
  This rule validates that tables have more than one row.
  """

  alias DocSpec.Core.Validation.Writer.Severity
  alias DocSpec.Spec.Table

  use DocSpec.Core.Validation.Writer.Rule,
    severity: Severity.error(),
    rule: "table-needs-multiple-rows",
    ruleset: "https://validation.spec.docspec.io/",
    # @TODO set `ruleset_version` to a real version
    ruleset_version: "unknown",
    validates: [Table]

  @impl true
  def valid?(%Table{children: children}, _),
    do: length(children) > 1
end
