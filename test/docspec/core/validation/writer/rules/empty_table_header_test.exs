defmodule DocSpec.Core.Validation.Writer.Rules.EmptyTableHeaderTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias DocSpec.Core.Validation.Spec.Finding
  alias DocSpec.Core.Validation.Writer.Rules.EmptyTableHeader
  alias DocSpec.Core.Validation.Writer.Severity
  alias DocSpec.Core.Validation.Writer.State

  @empty_table_header_1 %DocSpec.Spec.TableHeader{
    id: "table-header-id",
    children: []
  }

  @empty_table_header_2 %DocSpec.Spec.TableHeader{
    id: "table-header-id",
    children: [
      %DocSpec.Spec.Paragraph{id: "paragraph-id"}
    ]
  }

  @empty_table_header_3 %DocSpec.Spec.TableHeader{
    id: "table-header-id",
    children: [
      %DocSpec.Spec.Paragraph{
        id: "paragraph-id",
        children: [%DocSpec.Spec.Text{id: "text-id", text: ""}]
      }
    ]
  }

  @table_header_with_text %DocSpec.Spec.TableHeader{
    id: "table-header-id",
    children: [
      %DocSpec.Spec.Paragraph{
        id: "paragraph-id",
        children: [%DocSpec.Spec.Text{id: "text-id", text: "Table header"}]
      }
    ]
  }

  describe "&make_finding/1" do
    test "returns expected" do
      assert EmptyTableHeader.make_finding("resource-id") ==
               %Finding{
                 resource_id: "resource-id",
                 rule: "empty-table-header",
                 ruleset: "https://dequeuniversity.com/rules/axe/html",
                 ruleset_version: "4.10",
                 severity: Severity.error(),
                 type: "https://validation.spec.docspec.io/Finding"
               }
    end
  end

  describe "&validate/2" do
    test "returns no issues when table header has text" do
      assert EmptyTableHeader.validate(@table_header_with_text, %State{}) == %State{}
    end

    test "returns issue when table header is empty" do
      assert EmptyTableHeader.validate(@empty_table_header_1, %State{}) ==
               %State{findings: [EmptyTableHeader.make_finding("table-header-id")]}

      assert EmptyTableHeader.validate(@empty_table_header_2, %State{}) ==
               %State{findings: [EmptyTableHeader.make_finding("table-header-id")]}

      assert EmptyTableHeader.validate(@empty_table_header_3, %State{}) ==
               %State{findings: [EmptyTableHeader.make_finding("table-header-id")]}
    end
  end
end
