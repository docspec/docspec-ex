defmodule DocSpec.Core.Validation.Writer.Rules.PageStartsWithHeadingOneTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias DocSpec.Core.Validation.Writer.Rules.PageStartsWithHeadingOne
  alias DocSpec.Core.Validation.Writer.State

  @document_starting_with_heading_1 %DocSpec.Spec.Document{
    id: "document-id",
    children: [
      %DocSpec.Spec.Heading{
        id: "heading-id",
        level: 1,
        children: [
          %DocSpec.Spec.Text{id: "h1-text-id", text: "Heading one"}
        ]
      }
    ]
  }

  @document_has_no_heading_1 %DocSpec.Spec.Document{
    id: "document-id",
    children: [
      %DocSpec.Spec.Heading{
        id: "heading-id",
        level: 2,
        children: [
          %DocSpec.Spec.Text{id: "h2-text-id", text: "Heading two"}
        ]
      }
    ]
  }

  @document_starting_with_paragraph %DocSpec.Spec.Document{
    id: "document-id",
    children: [
      %DocSpec.Spec.Paragraph{
        id: "paragraph-id",
        children: [
          %DocSpec.Spec.Text{id: "text-id", text: "There is no heading one"}
        ]
      },
      %DocSpec.Spec.Heading{
        id: "heading-id",
        level: 1,
        children: [
          %DocSpec.Spec.Text{id: "h1-text-id", text: "Heading one"}
        ]
      }
    ]
  }

  describe "&make_finding/1" do
    test "returns expected" do
      assert PageStartsWithHeadingOne.make_finding("resource-id") ==
               %DocSpec.Core.Validation.Spec.Finding{
                 resource_id: "resource-id",
                 rule: "page-starts-with-heading-one",
                 ruleset: "https://validation.spec.docspec.io/",
                 ruleset_version: "unknown",
                 severity: :warning,
                 type: "https://validation.spec.docspec.io/Finding"
               }
    end
  end

  describe "&validate/2" do
    test "accepts document starting with heading 1" do
      assert PageStartsWithHeadingOne.validate(@document_starting_with_heading_1, %State{}) ==
               %State{}
    end

    test "accepts document that has no heading 1" do
      assert PageStartsWithHeadingOne.validate(@document_has_no_heading_1, %State{}) ==
               %State{}
    end

    test "rejects document that has a heading 1 but does not start with it" do
      assert PageStartsWithHeadingOne.validate(@document_starting_with_paragraph, %State{}) ==
               %State{findings: [PageStartsWithHeadingOne.make_finding("heading-id")]}
    end
  end
end
