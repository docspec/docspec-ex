defmodule DocSpec.Core.Validation.Writer.Rules.HeadingLevelValidTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias DocSpec.Core.Validation.Spec.Finding
  alias DocSpec.Core.Validation.Writer.Rules.HeadingLevelValid
  alias DocSpec.Core.Validation.Writer.Severity
  alias DocSpec.Core.Validation.Writer.State

  defp create_heading(level) do
    %DocSpec.Spec.Heading{
      id: "resource-id",
      level: level,
      children: [
        %DocSpec.Spec.Text{id: "text-id", text: "Heading with level #{level}"}
      ]
    }
  end

  describe "&make_finding/1" do
    test "returns expected" do
      assert HeadingLevelValid.make_finding("resource-id") ==
               %Finding{
                 resource_id: "resource-id",
                 rule: "invalid-heading-level",
                 ruleset: "https://html.spec.whatwg.org/",
                 ruleset_version: "5",
                 severity: Severity.error(),
                 type: "https://validation.spec.docspec.io/Finding"
               }
    end
  end

  describe "&validate/2" do
    test "returns finding with level -1" do
      assert HeadingLevelValid.validate(create_heading(-1), %State{}) ==
               %State{findings: [HeadingLevelValid.make_finding("resource-id")]}
    end

    test "returns finding with level 7" do
      assert HeadingLevelValid.validate(create_heading(7), %State{}) ==
               %State{findings: [HeadingLevelValid.make_finding("resource-id")]}
    end

    test "returns no finding with level 1" do
      assert HeadingLevelValid.validate(create_heading(1), %State{}) ==
               %State{}
    end
  end
end
