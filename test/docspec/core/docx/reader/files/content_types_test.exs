defmodule DocSpec.Core.DOCX.Reader.Files.ContentTypesTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias DocSpec.Core.DOCX.Reader.{Files.ContentTypes, XML}

  doctest ContentTypes

  describe "parse/1" do
    test "parses the content types file from calibre-demo.docx" do
      content_types_file = Path.join([__DIR__, "fixtures", "calibre-demo-content-types.xml"])
      types = XML.read!(content_types_file) |> ContentTypes.parse()

      assert types == %ContentTypes{
               defaults: %{
                 "gif" => "image/gif",
                 "odttf" => "application/vnd.openxmlformats-officedocument.obfuscatedFont",
                 "png" => "image/png",
                 "rels" => "application/vnd.openxmlformats-package.relationships+xml",
                 "xml" => "application/xml"
               },
               overrides: %{
                 "/customXml/itemProps1.xml" =>
                   "application/vnd.openxmlformats-officedocument.customXmlProperties+xml",
                 "/customXml/itemProps2.xml" =>
                   "application/vnd.openxmlformats-officedocument.customXmlProperties+xml",
                 "/docProps/app.xml" =>
                   "application/vnd.openxmlformats-officedocument.extended-properties+xml",
                 "/docProps/core.xml" =>
                   "application/vnd.openxmlformats-package.core-properties+xml",
                 "/word/document.xml" =>
                   "application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml",
                 "/word/endnotes.xml" =>
                   "application/vnd.openxmlformats-officedocument.wordprocessingml.endnotes+xml",
                 "/word/fontTable.xml" =>
                   "application/vnd.openxmlformats-officedocument.wordprocessingml.fontTable+xml",
                 "/word/footnotes.xml" =>
                   "application/vnd.openxmlformats-officedocument.wordprocessingml.footnotes+xml",
                 "/word/numbering.xml" =>
                   "application/vnd.openxmlformats-officedocument.wordprocessingml.numbering+xml",
                 "/word/settings.xml" =>
                   "application/vnd.openxmlformats-officedocument.wordprocessingml.settings+xml",
                 "/word/styles.xml" =>
                   "application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml",
                 "/word/theme/theme1.xml" =>
                   "application/vnd.openxmlformats-officedocument.theme+xml",
                 "/word/webSettings.xml" =>
                   "application/vnd.openxmlformats-officedocument.wordprocessingml.webSettings+xml"
               }
             }
    end
  end
end
