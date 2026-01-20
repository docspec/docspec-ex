defmodule DocSpec.Core.Validation.Writer.Rules.ImageMustHaveAltTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias DocSpec.Core.Validation.Spec.Finding
  alias DocSpec.Core.Validation.Writer.Rules.ImageMustHaveAlt
  alias DocSpec.Core.Validation.Writer.Severity
  alias DocSpec.Core.Validation.Writer.State

  @decorative_image_without_alt %DocSpec.Spec.Image{
    id: "resource-id",
    source: "https://example.com/image.jpg",
    alternative_text: "",
    decorative: true
  }

  @decorative_image_with_alt %DocSpec.Spec.Image{
    id: "resource-id",
    source: "https://example.com/image.jpg",
    alternative_text: "This is a decorative image",
    decorative: true
  }

  @non_decorative_image_without_alt %DocSpec.Spec.Image{
    id: "resource-id",
    source: "https://example.com/image.jpg",
    alternative_text: "",
    decorative: false
  }

  @non_decorative_image_with_alt %DocSpec.Spec.Image{
    id: "resource-id",
    source: "https://example/image.jpg",
    alternative_text: "This is a non-decorative image",
    decorative: false
  }

  describe "&make_finding/1" do
    test "returns expected" do
      assert ImageMustHaveAlt.make_finding("resource-id") ==
               %Finding{
                 resource_id: "resource-id",
                 rule: "image-alt",
                 ruleset: "https://dequeuniversity.com/rules/axe/html",
                 ruleset_version: "4.10",
                 severity: Severity.error(),
                 type: "https://validation.spec.docspec.io/Finding"
               }
    end
  end

  describe "&validate/2" do
    test "returns no findings when decorative image has alt" do
      assert ImageMustHaveAlt.validate(@decorative_image_with_alt, %State{}) == %State{}
    end

    test "returns no findings when non-decorative image has alt" do
      assert ImageMustHaveAlt.validate(@non_decorative_image_with_alt, %State{}) == %State{}
    end

    test "returns no findings when decorative image has no alt" do
      assert ImageMustHaveAlt.validate(@decorative_image_without_alt, %State{}) == %State{}
    end

    test "returns finding when non-decorative image has no alt" do
      assert ImageMustHaveAlt.validate(@non_decorative_image_without_alt, %State{}) ==
               %State{findings: [ImageMustHaveAlt.make_finding("resource-id")]}
    end
  end
end
