defmodule DocSpec.Core.Validation.Writer.Rules.EmptyDefinitionTermTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias DocSpec.Core.Validation.Spec.Finding
  alias DocSpec.Core.Validation.Writer.Rules.EmptyDefinitionTerm
  alias DocSpec.Core.Validation.Writer.Severity
  alias DocSpec.Core.Validation.Writer.State

  @empty_definition_term_1 %DocSpec.Spec.DefinitionTerm{
    id: "resource-id",
    children: []
  }

  @empty_definition_term_2 %DocSpec.Spec.DefinitionTerm{
    id: "resource-id",
    children: [%DocSpec.Spec.Text{id: "text-id", text: "  "}]
  }

  @non_empty_definition_term %DocSpec.Spec.DefinitionTerm{
    id: "resource-id",
    children: [%DocSpec.Spec.Text{id: "text-id", text: "text"}]
  }

  describe "&make_finding/1" do
    test "returns expected" do
      assert EmptyDefinitionTerm.make_finding("resource-id") ==
               %Finding{
                 resource_id: "resource-id",
                 rule: "empty-definition-term",
                 ruleset: "https://validation.spec.docspec.io/",
                 ruleset_version: "unknown",
                 severity: Severity.error(),
                 type: "https://validation.spec.docspec.io/Finding"
               }
    end
  end

  describe "&validate/2" do
    test "returns no issues when definition term has text" do
      assert EmptyDefinitionTerm.validate(@non_empty_definition_term, %State{}) == %State{}
    end

    test "returns issue when definition term is empty" do
      assert EmptyDefinitionTerm.validate(@empty_definition_term_1, %State{}) ==
               %State{findings: [EmptyDefinitionTerm.make_finding("resource-id")]}

      assert EmptyDefinitionTerm.validate(@empty_definition_term_2, %State{}) ==
               %State{findings: [EmptyDefinitionTerm.make_finding("resource-id")]}
    end
  end
end
