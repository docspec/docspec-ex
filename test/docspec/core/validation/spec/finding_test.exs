defmodule DocSpec.Core.Validation.Spec.FindingTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias DocSpec.Core.Validation.Spec.Finding

  doctest Finding

  @valid_attrs %{
    resource_id: "550e8400-e29b-41d4-a716-446655440000",
    severity: :error,
    rule: "empty-heading",
    ruleset: "https://wcag.nl/",
    ruleset_version: "1.0"
  }

  describe "resource_type/0" do
    test "returns the resource type URI" do
      assert Finding.resource_type() ==
               "https://validation.spec.docspec.io/Finding"
    end
  end

  describe "struct" do
    test "can be created with all required fields" do
      finding = %Finding{
        resource_id: "test-id",
        severity: :error,
        rule: "test-rule",
        ruleset: "https://example.com/",
        ruleset_version: "1.0"
      }

      assert finding.type == Finding.resource_type()
      assert finding.resource_id == "test-id"
      assert finding.severity == :error
    end

    test "has default type" do
      finding = %Finding{
        resource_id: "test-id",
        severity: :warning,
        rule: "test-rule",
        ruleset: "https://example.com/",
        ruleset_version: "1.0"
      }

      assert finding.type == "https://validation.spec.docspec.io/Finding"
    end
  end

  describe "new/1" do
    test "creates a finding with valid attributes" do
      assert {:ok, finding} = Finding.new(@valid_attrs)

      assert finding.resource_id == @valid_attrs.resource_id
      assert finding.severity == :error
      assert finding.rule == "empty-heading"
      assert finding.ruleset == "https://wcag.nl/"
      assert finding.ruleset_version == "1.0"
      assert finding.type == Finding.resource_type()
    end

    test "returns error when missing required fields" do
      assert {:error, message} = Finding.new(%{resource_id: "test"})
      assert message =~ "Missing required fields"
      assert message =~ "severity"
      assert message =~ "rule"
    end

    test "allows custom type to be specified" do
      attrs = Map.put(@valid_attrs, :type, "custom-type")
      assert {:ok, finding} = Finding.new(attrs)
      assert finding.type == "custom-type"
    end

    test "supports all severity levels" do
      for severity <- [:error, :warning, :notice] do
        attrs = Map.put(@valid_attrs, :severity, severity)
        assert {:ok, finding} = Finding.new(attrs)
        assert finding.severity == severity
      end
    end
  end

  describe "new!/1" do
    test "creates a finding with valid attributes" do
      finding = Finding.new!(@valid_attrs)

      assert finding.resource_id == @valid_attrs.resource_id
      assert finding.severity == :error
    end

    test "raises on missing required fields" do
      assert_raise ArgumentError, ~r/Missing required fields/, fn ->
        Finding.new!(%{resource_id: "test"})
      end
    end
  end
end
