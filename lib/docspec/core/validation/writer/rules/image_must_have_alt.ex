defmodule DocSpec.Core.Validation.Writer.Rules.ImageMustHaveAlt do
  @moduledoc """
  This rule validates that an image has an alternative text, or is marked as decorative.
  """

  alias DocSpec.Core.Validation.Writer.Severity
  alias DocSpec.Spec.{Content, Image}

  use DocSpec.Core.Validation.Writer.Rule,
    severity: Severity.error(),
    rule: "image-alt",
    ruleset: "https://dequeuniversity.com/rules/axe/html",
    ruleset_version: "4.10",
    validates: [Image]

  @impl true
  def valid?(%Image{decorative: false, alternative_text: alt}, _),
    do: alt |> Content.discernible_text?()
end
