defmodule DocSpec.Core.DOCX.Reader.Files.CorePropertiesTest do
  @moduledoc false
  use ExUnit.Case, async: true
  doctest DocSpec.Core.DOCX.Reader.Files.CoreProperties

  alias DocSpec.Core.DOCX.Reader.Files.CoreProperties

  @core_props_file Path.join([__DIR__, "fixtures", "core-properties.xml"])

  test "reads and parses a core-properties.xml file" do
    core_props = CoreProperties.read!(@core_props_file)

    assert core_props == %{
             "dc:title" => "Jesus He Knows Me",
             "dc:creator" => "Genesis",
             "cp:keywords" =>
               "song, music, satire, televangelists, religious hypocrisy, pop-rock, social commentary",
             "dc:description" =>
               "Satirical song that mocks televangelists and religious hypocrisy, blending upbeat, catchy pop-rock with biting social commentary.",
             "cp:lastModifiedBy" => "Phil Collins",
             "cp:revision" => "42",
             "dcterms:created" => "1991-03-15T07:56:00Z",
             "dcterms:modified" => "1991-07-10T01:23:01Z"
           }
  end

  test "converts the dc core properties from the fixture into DocumentMeta" do
    core_props = CoreProperties.read!(@core_props_file)
    metadata = CoreProperties.convert(core_props)

    assert metadata == %DocSpec.Spec.DocumentMeta{
             title: "Jesus He Knows Me",
             authors: [%DocSpec.Spec.Author{name: "Genesis"}],
             description:
               "Satirical song that mocks televangelists and religious hypocrisy, blending upbeat, catchy pop-rock with biting social commentary.",
             language: nil
           }
  end

  test "returns nil for core properties with no relevant values" do
    core_props = %{"dc:title" => ""}
    metadata = CoreProperties.convert(core_props)

    assert metadata == nil
  end
end
