defmodule DocSpec.Core.DOCX.Reader.Files.NumberingsTest do
  @moduledoc false
  use ExUnit.Case, async: true
  import DocSpec.Test.Snapshot
  doctest DocSpec.Core.DOCX.Reader.Files.Numberings

  alias DocSpec.Core.DOCX.Reader.Files.Numberings

  test "reads and parses the numbering.xml file from calibre-demo" do
    numberings_file = Path.join([__DIR__, "fixtures", "calibre-demo-numbering.xml"])
    numberings = Numberings.read!(numberings_file)

    snapshot_name = "DocSpec.Core.DOCX.Reader.Files.NumberingsTest/calibre-demo"
    assert_snapshot(numberings, snapshot_name, format: :exs)
  end
end
