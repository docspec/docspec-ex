defmodule DocSpec.Core.Tiptap.ReaderTest do
  @moduledoc false
  use ExUnit.Case, async: true
  doctest DocSpec.Core.Tiptap.Reader

  import DocSpec.Test.Snapshot

  use Mimic

  alias DocSpec.Core.Tiptap.Reader
  alias DocSpec.Spec.{Document, DocumentSpecification, Schema}

  # Use native Tiptap JSON fixtures
  @fixtures_dir Path.join([__DIR__, "../../../fixtures/tiptap"])
  @fixtures @fixtures_dir
            |> Path.join("*.json")
            |> Path.wildcard()
            |> Enum.filter(&File.regular?/1)

  if @fixtures == [] do
    raise "No fixtures found in #{@fixtures_dir}"
  end

  for filename <- @fixtures do
    fixture_name = Path.basename(filename)

    test "successfully converts #{fixture_name}" do
      stub(Ecto.UUID, :generate, fn -> "00000000-0000-4000-8000-000000000000" end)

      filename = unquote(filename)
      fixture_name = unquote(fixture_name)

      # Read native Tiptap JSON and convert to DocSpec
      {:ok, spec = %DocumentSpecification{document: %Document{}}} =
        filename
        |> File.read!()
        |> Jason.decode!(keys: :atoms)
        |> Reader.convert()

      # Snapshot the DocSpec output
      snapshot_path = "DocSpec.Core.Tiptap.Reader/#{fixture_name}"
      json_data = spec |> Jason.encode!() |> Jason.decode!()
      assert_snapshot(json_data, snapshot_path, format: :json)

      # Verify the result can be re-parsed as a valid DocSpec specification
      assert {:ok, %DocumentSpecification{}} =
               json_data |> Schema.decode_keys() |> DocumentSpecification.new()
    end
  end

  describe "uuid_if_nil/1 behavior" do
    test "generates UUIDs for elements without id attributes" do
      input = %{
        type: "doc",
        content: [
          %{
            type: "paragraph",
            content: [
              %{
                type: "text",
                text: "Text without id"
              }
            ]
          }
        ]
      }

      {:ok, %DocumentSpecification{document: document = %Document{}}} = Reader.convert(input)

      # Document should have a generated UUID
      assert is_binary(document.id)

      assert String.match?(
               document.id,
               ~r/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/
             )

      # Paragraph should have a generated UUID
      [paragraph] = document.children
      assert is_binary(paragraph.id)

      assert String.match?(
               paragraph.id,
               ~r/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/
             )

      # Text should have a generated UUID
      [text] = paragraph.children
      assert is_binary(text.id)

      assert String.match?(
               text.id,
               ~r/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/
             )
    end
  end
end
