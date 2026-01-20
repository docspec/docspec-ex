defmodule DocSpec.Core.DOCX.Reader.Files.RelationshipTest do
  @moduledoc false
  use ExUnit.Case, async: true
  import DocSpec.Test.Snapshot
  doctest DocSpec.Core.DOCX.Reader.Files.Relationship

  alias DocSpec.Core.DOCX.Reader.Files.Relationship

  test "reads and parses the document.xml.rels file from calibre-demo" do
    rels_file = Path.join([__DIR__, "fixtures", "calibre-demo-document-relationships.xml"])
    rels = Relationship.read!(rels_file)

    snapshot_name = "DocSpec.Core.DOCX.Reader.Files.RelationshipTest/calibre-demo"
    assert_snapshot(rels, snapshot_name, format: :exs)
  end
end
