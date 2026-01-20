defmodule DocSpec.Core.DOCX.Reader.Files.StylesTest do
  @moduledoc false
  use ExUnit.Case, async: true
  import DocSpec.Test.Snapshot
  doctest DocSpec.Core.DOCX.Reader.Files.Styles

  alias DocSpec.Core.DOCX.Reader.Files.Styles

  test "reads and parses the styles.xml file from calibre-demo" do
    styles_file = Path.join([__DIR__, "fixtures", "calibre-demo-styles.xml"])
    styles = Styles.read!(styles_file)

    snapshot_name = "DocSpec.Core.DOCX.Reader.Files.StylesTest/calibre-demo"
    assert_snapshot(styles, snapshot_name, format: :exs)
  end
end
