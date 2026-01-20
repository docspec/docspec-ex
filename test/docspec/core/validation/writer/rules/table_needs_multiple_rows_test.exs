defmodule DocSpec.Core.Validation.Writer.Rules.TableNeedsMultipleRowsTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias DocSpec.Core.Validation.Spec.Finding
  alias DocSpec.Core.Validation.Writer.Rules.TableNeedsMultipleRows
  alias DocSpec.Core.Validation.Writer.Severity
  alias DocSpec.Core.Validation.Writer.State

  @table_with_no_rows %DocSpec.Spec.Table{
    id: "table-id",
    children: []
  }

  @table_with_one_row %DocSpec.Spec.Table{
    id: "table-id",
    children: [
      %DocSpec.Spec.TableRow{id: "row-id"}
    ]
  }

  @table_with_multiple_rows %DocSpec.Spec.Table{
    id: "table-id",
    children: [
      %DocSpec.Spec.TableRow{id: "row-id-1"},
      %DocSpec.Spec.TableRow{id: "row-id-2"}
    ]
  }

  describe "&make_finding/1" do
    test "returns expected" do
      assert TableNeedsMultipleRows.make_finding("resource-id") ==
               %Finding{
                 resource_id: "resource-id",
                 rule: "table-needs-multiple-rows",
                 ruleset: "https://validation.spec.docspec.io/",
                 ruleset_version: "unknown",
                 severity: Severity.error(),
                 type: "https://validation.spec.docspec.io/Finding"
               }
    end
  end

  describe "&validate/2" do
    test "returns finding when table has no rows" do
      assert TableNeedsMultipleRows.validate(@table_with_no_rows, %State{}) ==
               %State{findings: [TableNeedsMultipleRows.make_finding("table-id")]}
    end

    test "returns finding when table has one row" do
      assert TableNeedsMultipleRows.validate(@table_with_one_row, %State{}) ==
               %State{findings: [TableNeedsMultipleRows.make_finding("table-id")]}
    end

    test "returns no findings when table has multiple rows" do
      assert TableNeedsMultipleRows.validate(@table_with_multiple_rows, %State{}) ==
               %State{}
    end
  end
end
