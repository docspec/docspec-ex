defmodule DocSpec.Core.Validation.Writer.Rules.LinkNameTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias DocSpec.Core.Validation.Spec.Finding
  alias DocSpec.Core.Validation.Writer.Rules.LinkName
  alias DocSpec.Core.Validation.Writer.Severity
  alias DocSpec.Core.Validation.Writer.State

  @link_with_text %DocSpec.Spec.Link{
    id: "link-id",
    uri: "https://example.com",
    text: "This is a link"
  }

  @link_without_text %DocSpec.Spec.Link{
    id: "link-id",
    uri: "https://example.com",
    text: ""
  }

  describe "&make_finding/1" do
    test "returns expected" do
      assert LinkName.make_finding("resource-id") ==
               %Finding{
                 resource_id: "resource-id",
                 rule: "link-name",
                 ruleset: "https://dequeuniversity.com/rules/axe/html",
                 ruleset_version: "4.10",
                 severity: Severity.error(),
                 type: "https://validation.spec.docspec.io/Finding"
               }
    end
  end

  describe "&validate/2" do
    test "returns no issues when link has text" do
      assert LinkName.validate(@link_with_text, %State{}) == %State{}
    end

    test "returns issue when link has no text" do
      assert LinkName.validate(@link_without_text, %State{}) ==
               %State{findings: [LinkName.make_finding("link-id")]}
    end
  end
end
