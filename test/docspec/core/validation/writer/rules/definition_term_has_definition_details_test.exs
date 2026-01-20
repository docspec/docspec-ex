defmodule DocSpec.Core.Validation.Writer.Rules.DefinitionTermHasDefinitionDetailsTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias DocSpec.Core.Validation.Spec.Finding
  alias DocSpec.Core.Validation.Writer.Rules.DefinitionTermHasDefinitionDetails
  alias DocSpec.Core.Validation.Writer.Severity
  alias DocSpec.Core.Validation.Writer.State

  @definition_term %DocSpec.Spec.DefinitionTerm{
    id: "term-id",
    children: [%DocSpec.Spec.Text{id: "text-id", text: "Term"}]
  }

  @definition_list %DocSpec.Spec.DefinitionList{
    id: "definition-list-id",
    children: [
      @definition_term
    ]
  }

  describe "&make_finding/1" do
    test "returns expected" do
      assert DefinitionTermHasDefinitionDetails.make_finding("resource-id") ==
               %Finding{
                 resource_id: "resource-id",
                 rule: "definition-term-has-definition-details",
                 ruleset: "https://validation.spec.docspec.io/",
                 ruleset_version: "unknown",
                 severity: Severity.error(),
                 type: "https://validation.spec.docspec.io/Finding"
               }
    end
  end

  describe "&validate/2" do
    test "returns finding when definition term has no definition details" do
      assert DefinitionTermHasDefinitionDetails.validate(@definition_term, %State{
               definition_term_id_without_details: "first-term"
             }) ==
               %State{
                 definition_term_id_without_details: "term-id",
                 findings: [DefinitionTermHasDefinitionDetails.make_finding("first-term")]
               }
    end

    test "returns no finding when definition term has definition details" do
      assert DefinitionTermHasDefinitionDetails.validate(@definition_term, %State{}) ==
               %State{definition_term_id_without_details: "term-id"}
    end

    test "state is reset when definition list is encountered" do
      assert DefinitionTermHasDefinitionDetails.validate(@definition_list, %State{
               definition_term_id_without_details: "first-term"
             }) ==
               %State{}
    end
  end
end
