#!/usr/bin/env elixir

# Convert reader snapshots to EPUB format for validation with epubcheck
# Usage: mix run bin/convert_fixtures_to_epub.exs [output_dir]
# Example: mix run bin/convert_fixtures_to_epub.exs epub_output

alias DocSpec.Core.EPUB.Writer, as: EPUBWriter
alias DocSpec.Spec.{DocumentSpecification, Schema}

output_dir = System.argv() |> List.first() || "epub_output"

IO.puts("Converting reader snapshots to EPUB...")
IO.puts("Output directory: #{output_dir}\n")

File.mkdir_p!(output_dir)

# Find all reader snapshots (expected.json files from DOCX and Tiptap readers)
snapshots =
  Path.wildcard("test/snapshots/DocSpec.Core.*.Reader/*/expected.json")
  |> Enum.filter(&File.exists?/1)

if snapshots == [] do
  IO.puts("Error: No snapshots found!")
  System.halt(1)
end

IO.puts("Found #{length(snapshots)} reader snapshots\n")

results =
  snapshots
  |> Enum.with_index(1)
  |> Enum.map(fn {snapshot, index} ->
    # Extract reader type and fixture name from path
    # e.g., "test/snapshots/DocSpec.Core.DOCX.Reader/calibre-demo.docx/expected.json"
    parts = Path.split(snapshot)
    reader = Enum.at(parts, 2) |> String.replace("DocSpec.Core.", "") |> String.replace(".Reader", "")
    fixture = Enum.at(parts, 3) |> String.replace(~r/\.(docx|json)$/, "")

    basename = "#{String.downcase(reader)}_#{fixture}"
    dest = Path.join(output_dir, "#{basename}.epub")

    IO.puts("[#{index}/#{length(snapshots)}] #{reader}: #{fixture}")

    try do
      spec =
        snapshot
        |> File.read!()
        |> Jason.decode!()
        |> Schema.decode_keys()
        |> DocumentSpecification.new!()

      :ok = EPUBWriter.convert!(spec, dest)
      IO.puts("  ✓ #{dest}\n")
      :ok
    rescue
      e ->
        IO.puts("  ✗ Error: #{Exception.message(e)}\n")
        :error
    end
  end)

success = Enum.count(results, &(&1 == :ok))
failed = Enum.count(results, &(&1 == :error))

IO.puts("Done! #{success} succeeded, #{failed} failed")
IO.puts("EPUBs saved to #{output_dir}/")

if failed > 0 do
  System.halt(1)
end
