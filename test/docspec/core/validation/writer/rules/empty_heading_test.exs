defmodule DocSpec.Core.Validation.Writer.Rules.EmptyHeadingTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias DocSpec.Core.Validation.Spec.Finding
  alias DocSpec.Core.Validation.Writer.Rules.EmptyHeading
  alias DocSpec.Core.Validation.Writer.Severity
  alias DocSpec.Core.Validation.Writer.State

  @empty_heading_1 %DocSpec.Spec.Heading{
    id: "heading-id",
    level: 1,
    children: []
  }

  @empty_heading_2 %DocSpec.Spec.Heading{
    id: "heading-id",
    level: 2,
    children: [%DocSpec.Spec.Text{id: "text-id", text: "  "}]
  }

  @non_empty_heading %DocSpec.Spec.Heading{
    id: "heading-id",
    level: 1,
    children: [%DocSpec.Spec.Text{id: "text-id", text: "Heading one"}]
  }

  describe "&make_finding/1" do
    test "returns expected" do
      assert EmptyHeading.make_finding("resource-id") ==
               %Finding{
                 resource_id: "resource-id",
                 rule: "empty-heading",
                 ruleset: "https://dequeuniversity.com/rules/axe/html",
                 ruleset_version: "4.10",
                 severity: Severity.error(),
                 type: "https://validation.spec.docspec.io/Finding"
               }
    end
  end

  describe "&validate/2" do
    test "returns no issues when heading has text" do
      assert EmptyHeading.validate(@non_empty_heading, %State{}) == %State{}
    end

    test "returns issue when heading is empty" do
      assert EmptyHeading.validate(@empty_heading_1, %State{}) ==
               %State{findings: [EmptyHeading.make_finding("heading-id")]}

      assert EmptyHeading.validate(@empty_heading_2, %State{}) ==
               %State{findings: [EmptyHeading.make_finding("heading-id")]}
    end
  end
end
