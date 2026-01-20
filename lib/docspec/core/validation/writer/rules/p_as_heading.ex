defmodule DocSpec.Core.Validation.Writer.Rules.PAsHeading do
  @moduledoc """
  Ensures paragraph elements are not used to style headings.
  """

  alias DocSpec.Core.Validation.Writer.Severity
  alias DocSpec.Spec.{Content, Paragraph, Styles}

  use DocSpec.Core.Validation.Writer.Rule,
    severity: Severity.warning(),
    rule: "p-as-heading",
    ruleset: "https://dequeuniversity.com/rules/axe/html",
    ruleset_version: "4.10",
    validates: [Paragraph]

  @impl true
  def valid?(paragraph = %Paragraph{children: children}, _) do
    !Enum.all?(children, &bold?/1) || !Content.discernible_text?(paragraph)
  end

  @spec bold?(term()) :: boolean()
  defp bold?(%{styles: %Styles{bold: true}}),
    do: true

  defp bold?(%{styles: nil, text: text}),
    do: !Content.discernible_text?(text)

  defp bold?(%{styles: %Styles{bold: false}, text: text}),
    do: !Content.discernible_text?(text)

  defp bold?(_),
    do: false
end
