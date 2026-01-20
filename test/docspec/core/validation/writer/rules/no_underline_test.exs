defmodule DocSpec.Core.Validation.Writer.Rules.NoUnderlineTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias DocSpec.Core.Validation.Spec.Finding
  alias DocSpec.Core.Validation.Writer.Rules.NoUnderline
  alias DocSpec.Core.Validation.Writer.Severity
  alias DocSpec.Core.Validation.Writer.State
  alias DocSpec.Spec.Styles

  @underlined_text %DocSpec.Spec.Text{
    id: "text-id",
    text: "This is underlined",
    styles: %Styles{underline: true}
  }

  @non_underlined_text %DocSpec.Spec.Text{
    id: "text-id",
    text: "This is not underlined",
    styles: nil
  }

  @underlined_link %DocSpec.Spec.Link{
    id: "link-id",
    text: "This is underlined",
    styles: %Styles{underline: true},
    uri: "https://example.com"
  }

  @non_underlined_link %DocSpec.Spec.Link{
    id: "link-id",
    text: "This is not underlined",
    styles: nil,
    uri: "https://example.com"
  }

  describe "&make_finding/1" do
    test "returns expected" do
      assert NoUnderline.make_finding("resource-id") ==
               %Finding{
                 resource_id: "resource-id",
                 rule: "no-underline",
                 ruleset: "https://validation.spec.docspec.io/",
                 ruleset_version: "unknown",
                 severity: Severity.warning(),
                 type: "https://validation.spec.docspec.io/Finding"
               }
    end
  end

  describe "&validate/2" do
    test "returns no findings for non-underlined text" do
      assert NoUnderline.validate(@non_underlined_text, %State{}) == %State{}
    end

    test "returns no findings for non-underlined link" do
      assert NoUnderline.validate(@non_underlined_link, %State{}) == %State{}
    end

    test "returns finding for underlined text" do
      assert NoUnderline.validate(@underlined_text, %State{}) == %State{
               findings: [NoUnderline.make_finding("text-id")]
             }
    end

    test "returns finding for underlined link" do
      assert NoUnderline.validate(@underlined_link, %State{}) == %State{
               findings: [NoUnderline.make_finding("link-id")]
             }
    end
  end
end
