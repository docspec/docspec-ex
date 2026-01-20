defmodule DocSpec.Core.Validation.Writer.Rules.EmptyDefinitionDetailsTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias DocSpec.Core.Validation.Spec.Finding
  alias DocSpec.Core.Validation.Writer.Rules.EmptyDefinitionDetails
  alias DocSpec.Core.Validation.Writer.Severity
  alias DocSpec.Core.Validation.Writer.State

  @empty_definition_details_1 %DocSpec.Spec.DefinitionDetails{
    id: "definition-details-id",
    children: []
  }

  @empty_definition_details_2 %DocSpec.Spec.DefinitionDetails{
    id: "definition-details-id",
    children: [%DocSpec.Spec.Text{id: "text-id", text: "  "}]
  }

  @non_empty_definition_details %DocSpec.Spec.DefinitionDetails{
    id: "definition-details-id",
    children: [%DocSpec.Spec.Text{id: "text-id", text: "text"}]
  }

  describe "&make_finding/1" do
    test "returns expected" do
      assert EmptyDefinitionDetails.make_finding("resource-id") ==
               %Finding{
                 resource_id: "resource-id",
                 rule: "empty-definition-details",
                 ruleset: "https://validation.spec.docspec.io/",
                 ruleset_version: "unknown",
                 severity: Severity.error(),
                 type: "https://validation.spec.docspec.io/Finding"
               }
    end
  end

  describe "&validate/2" do
    test "returns no issues when definition details has text" do
      assert EmptyDefinitionDetails.validate(@non_empty_definition_details, %State{}) == %State{}
    end

    test "returns issue when definition details is empty" do
      assert EmptyDefinitionDetails.validate(@empty_definition_details_1, %State{}) ==
               %State{findings: [EmptyDefinitionDetails.make_finding("definition-details-id")]}

      assert EmptyDefinitionDetails.validate(@empty_definition_details_2, %State{}) ==
               %State{findings: [EmptyDefinitionDetails.make_finding("definition-details-id")]}
    end
  end
end
