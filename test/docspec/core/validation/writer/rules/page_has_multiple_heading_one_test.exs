defmodule DocSpec.Core.Validation.Writer.Rules.PageHasMultipleHeadingOneTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias DocSpec.Core.Validation.Writer.Rules.PageHasMultipleHeadingOne
  alias DocSpec.Core.Validation.Writer.State

  @heading_one %DocSpec.Spec.Heading{
    id: "resource-id",
    level: 1,
    children: [
      %DocSpec.Spec.Text{id: "text-id", text: "Heading one"}
    ]
  }

  describe "&make_finding/1" do
    test "returns expected" do
      assert PageHasMultipleHeadingOne.make_finding("resource-id") ==
               %DocSpec.Core.Validation.Spec.Finding{
                 resource_id: "resource-id",
                 rule: "page-has-multiple-heading-one",
                 ruleset: "https://validation.spec.docspec.io/",
                 ruleset_version: "unknown",
                 severity: :warning,
                 type: "https://validation.spec.docspec.io/Finding"
               }
    end
  end

  describe "&validate/2" do
    test "rejects when validating a h1 while a h1 had already been encountered" do
      state = %State{encountered_heading_1?: true}

      assert PageHasMultipleHeadingOne.validate(@heading_one, state) ==
               %State{
                 encountered_heading_1?: true,
                 findings: [PageHasMultipleHeadingOne.make_finding("resource-id")]
               }
    end

    test "accepts when validating a h1 while a h1 had not yet been encountered" do
      state = %State{encountered_heading_1?: false}

      assert PageHasMultipleHeadingOne.validate(@heading_one, state) ==
               %State{encountered_heading_1?: true}
    end
  end
end
