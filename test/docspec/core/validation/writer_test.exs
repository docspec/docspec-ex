defmodule DocSpec.Core.Validation.WriterTest do
  @moduledoc false
  use ExUnit.Case, async: true

  import DocSpec.Test.Snapshot

  alias DocSpec.Core.Validation.Writer
  alias DocSpec.Spec.{Document, Schema}

  @fixtures_dir __DIR__ |> Path.join("./fixtures")
  @fixtures @fixtures_dir
            |> Path.join("**/*.json")
            |> Path.wildcard()
            |> Enum.filter(&File.regular?/1)

  if @fixtures == [] do
    raise "No fixtures found in #{@fixtures_dir}"
  end

  for filename <- @fixtures do
    test "successfully validates #{filename}" do
      filename = unquote(filename)

      findings =
        filename
        |> File.read!()
        |> Schema.decode_json!()
        |> Document.new!()
        |> Writer.validate()

      snapshot_path = "DocSpec.Core.Validation.Writer/#{filename |> Path.basename()}"
      assert_snapshot(findings, snapshot_path, format: :exs)
    end
  end
end
