defmodule DocSpec.Core.Tiptap.WriterTest do
  @moduledoc false
  use ExUnit.Case, async: true
  use Mimic
  doctest DocSpec.Core.Tiptap.Writer

  import DocSpec.Test.Snapshot

  alias DocSpec.Core.Tiptap.Writer
  alias DocSpec.JSON
  alias DocSpec.Spec.{Document, DocumentSpecification, Schema}
  alias DocSpec.Test.ReaderSnapshots

  # Use DocSpec JSON snapshots from ALL readers (valid documents only)
  @fixtures ReaderSnapshots.all()

  if @fixtures == [] do
    raise "No reader snapshots found"
  end

  for filename <- @fixtures do
    {format, fixture_name} = ReaderSnapshots.parse_path(filename)

    test "successfully converts #{format}/#{fixture_name}" do
      stub(Ecto.UUID, :generate, fn -> "00000000-0000-0000-0000-000000000000" end)

      filename = unquote(filename)
      format = unquote(format)
      fixture_name = unquote(fixture_name)

      spec =
        %DocumentSpecification{document: %Document{}} =
        filename
        |> File.read!()
        |> JSON.decode!()
        |> Schema.decode_keys()
        |> DocumentSpecification.new!()

      {:ok, tiptap} = Writer.convert(spec)

      # Normalize atom keys to string keys for snapshot comparison
      tiptap_normalized = tiptap |> Jason.encode!() |> Jason.decode!()

      # Organize snapshots by input format (docx, tiptap, etc.)
      snapshot_path = "DocSpec.Core.Tiptap.Writer/#{format}/#{fixture_name}"
      assert_snapshot(tiptap_normalized, snapshot_path, format: :json)
    end
  end
end
