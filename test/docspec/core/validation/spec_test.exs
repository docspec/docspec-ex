defmodule DocSpec.Core.Validation.SpecTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias DocSpec.Core.Validation.Spec
  alias DocSpec.Core.Validation.Spec.Finding

  doctest Spec

  describe "version/0" do
    test "returns the spec version" do
      assert is_binary(Spec.version())
      assert Spec.version() =~ ~r/^\d+\.\d+\.\d+$/
    end
  end

  describe "objects/0" do
    test "returns all object types" do
      assert Spec.objects() == [Finding]
    end
  end

  describe "type_uri/1" do
    test "returns URI for finding type" do
      assert Spec.type_uri(:finding) ==
               "https://validation.spec.docspec.io/Finding"
    end
  end
end
