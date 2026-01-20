defmodule DocSpec.Core.Validation.Writer.Rules.DefinitionListHasDefinitionTermTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias DocSpec.Core.Validation.Spec.Finding
  alias DocSpec.Core.Validation.Writer.Rules.DefinitionListHasDefinitionTerm
  alias DocSpec.Core.Validation.Writer.Severity
  alias DocSpec.Core.Validation.Writer.State

  @empty_definition_list %DocSpec.Spec.DefinitionList{
    id: "list-id",
    children: []
  }

  @definition_list_with_term %DocSpec.Spec.DefinitionList{
    id: "list-id",
    children: [
      %DocSpec.Spec.DefinitionTerm{
        id: "term",
        children: [%DocSpec.Spec.Text{id: "text1", text: "Term"}]
      },
      %DocSpec.Spec.DefinitionDetails{
        id: "details1",
        children: [%DocSpec.Spec.Text{id: "text2", text: "Details 1"}]
      },
      %DocSpec.Spec.DefinitionDetails{
        id: "details2",
        children: [%DocSpec.Spec.Text{id: "text3", text: "Details 2"}]
      }
    ]
  }

  @definition_list_without_term %DocSpec.Spec.DefinitionList{
    id: "list-id",
    children: [
      %DocSpec.Spec.DefinitionDetails{
        id: "details1",
        children: [%DocSpec.Spec.Text{id: "text2", text: "Details 1"}]
      },
      %DocSpec.Spec.DefinitionDetails{
        id: "details1",
        children: [%DocSpec.Spec.Text{id: "text2", text: "Details 1"}]
      }
    ]
  }

  describe "&make_finding/1" do
    test "returns expected" do
      assert DefinitionListHasDefinitionTerm.make_finding("resource-id") ==
               %Finding{
                 resource_id: "resource-id",
                 rule: "definition-list-has-definition-term",
                 ruleset: "https://validation.spec.docspec.io/",
                 ruleset_version: "unknown",
                 severity: Severity.error(),
                 type: "https://validation.spec.docspec.io/Finding"
               }
    end
  end

  describe "&validate/2" do
    test "returns no issues when definition list has term" do
      assert DefinitionListHasDefinitionTerm.validate(@definition_list_with_term, %State{}) ==
               %State{}
    end

    test "returns issue when definition list has no term" do
      assert DefinitionListHasDefinitionTerm.validate(@empty_definition_list, %State{}) ==
               %State{findings: [DefinitionListHasDefinitionTerm.make_finding("list-id")]}

      assert DefinitionListHasDefinitionTerm.validate(@definition_list_without_term, %State{}) ==
               %State{findings: [DefinitionListHasDefinitionTerm.make_finding("list-id")]}
    end
  end
end
