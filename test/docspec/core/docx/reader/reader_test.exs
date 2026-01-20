defmodule DocSpec.Core.DOCX.ReaderTest do
  @moduledoc """
  Tests for Docx conversions using fixtures.
  """

  use ExUnit.Case, async: true
  use Mimic
  import DocSpec.Test.Snapshot

  alias DocSpec.Core.DOCX.Reader
  alias DocSpec.Spec.{Document, DocumentSpecification, Schema}

  @fixtures_dir Path.join([__DIR__, "../../../../fixtures/docx"])
  @fixtures @fixtures_dir
            |> Path.join("**/*.docx")
            |> Path.wildcard()
            # Only accept regular files, not folders or symlinks
            |> Enum.filter(&File.regular?/1)
            # Ignore Word temporary files
            |> Enum.reject(&String.starts_with?(Path.basename(&1), "~$"))

  if @fixtures == [] do
    raise "No fixtures found in #{@fixtures_dir}"
  end

  for filename <- @fixtures do
    test "successfully converts #{filename}" do
      stub(Ecto.UUID, :generate, fn -> "00000000-0000-0000-0000-000000000000" end)
      filename = unquote(filename)

      docx = Reader.open!(filename)
      on_exit(fn -> Reader.close!(docx) end)

      # Convert to DocumentSpecification
      spec = %DocumentSpecification{document: %Document{}} = Reader.convert!(docx)

      # Encode struct first (uses clean encoder that omits defaults), then decode for snapshot
      json = spec |> Jason.encode!() |> Jason.decode!()

      snapshot_path = "DocSpec.Core.DOCX.Reader/#{filename |> Path.basename()}"
      assert_snapshot(json, snapshot_path, format: :json)

      # Verify the specification can be re-parsed
      assert {:ok, %DocumentSpecification{}} =
               json |> Schema.decode_keys() |> DocumentSpecification.new()
    end
  end
end
