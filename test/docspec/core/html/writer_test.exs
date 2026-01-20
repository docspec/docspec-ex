defmodule DocSpec.Core.HTML.WriterTest do
  @moduledoc false
  use ExUnit.Case, async: true

  import DocSpec.Test.Snapshot

  alias DocSpec.Core.HTML.Writer
  alias DocSpec.JSON
  alias DocSpec.Spec.{Document, DocumentSpecification, Schema}
  alias DocSpec.Test.ReaderSnapshots

  doctest Writer

  # Use DocSpec JSON snapshots from ALL readers (valid documents only)
  @fixtures ReaderSnapshots.all()

  if @fixtures == [] do
    raise "No reader snapshots found"
  end

  for filename <- @fixtures do
    {format, fixture_name} = ReaderSnapshots.parse_path(filename)

    test "successfully converts #{format}/#{fixture_name}" do
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

      html = Writer.convert(spec, pretty: true)

      {:ok, _} = Floki.parse_document(html)

      # Organize snapshots by input format (docx, tiptap, etc.)
      snapshot_path = "DocSpec.Core.HTML.Writer/#{format}/#{fixture_name}"
      assert_snapshot(html, snapshot_path, format: :html)
    end
  end
end
