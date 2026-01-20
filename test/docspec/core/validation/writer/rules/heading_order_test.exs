defmodule DocSpec.Core.Validation.Writer.Rules.HeadingOrderTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias DocSpec.Core.Validation.Spec.Finding
  alias DocSpec.Core.Validation.Writer.Rules.HeadingOrder
  alias DocSpec.Core.Validation.Writer.Severity
  alias DocSpec.Core.Validation.Writer.State

  defp create_heading(level) do
    %DocSpec.Spec.Heading{
      id: "resource-id",
      level: level,
      children: [%DocSpec.Spec.Text{id: "text-id", text: "Heading"}]
    }
  end

  describe "&make_finding/1" do
    test "returns expected" do
      assert HeadingOrder.make_finding("resource-id") ==
               %Finding{
                 resource_id: "resource-id",
                 rule: "heading-order",
                 ruleset: "https://dequeuniversity.com/rules/axe/html",
                 ruleset_version: "4.10",
                 severity: Severity.error(),
                 type: "https://validation.spec.docspec.io/Finding"
               }
    end
  end

  describe "&validate/2" do
    test "returns no findings when document starts with heading two" do
      assert HeadingOrder.validate(create_heading(2), %State{}) == %State{heading_level: 2}
    end

    test "returns finding when document skips heading two" do
      assert HeadingOrder.validate(create_heading(3), %State{heading_level: 1}) ==
               %State{heading_level: 3, findings: [HeadingOrder.make_finding("resource-id")]}
    end

    test "returns no findings when document has headings in order" do
      assert HeadingOrder.validate(create_heading(2), %State{heading_level: 1}) == %State{
               heading_level: 2
             }
    end
  end
end
