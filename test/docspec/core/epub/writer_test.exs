defmodule DocSpec.Core.EPUB.WriterTest do
  @moduledoc false

  use ExUnit.Case, async: true
  use Mimic

  doctest DocSpec.Core.EPUB.Writer

  import Exposure

  alias DocSpec.Core.EPUB.Writer
  alias DocSpec.Spec.{Document, DocumentSpecification, Schema}
  alias DocSpec.Test.ReaderSnapshots

  # Use DocSpec JSON snapshots from ALL readers (valid documents only)
  @fixtures ReaderSnapshots.all()

  if @fixtures == [] do
    raise "No reader snapshots found"
  end

  describe "&convert!/1" do
    for filename <- @fixtures do
      {format, fixture_name} = ReaderSnapshots.parse_path(filename)

      test_snapshot "successfully converts #{format}/#{fixture_name}" do
        DateTime
        |> expect(:utc_now, fn -> ~U[1970-01-01 00:00:00Z] end)

        spec =
          %DocumentSpecification{document: %Document{}} =
          unquote(filename)
          |> File.read!()
          |> Jason.decode!()
          |> Schema.decode_keys()
          |> DocumentSpecification.new!()

        {:ok, zip} = Writer.convert!(spec)

        {:ok, entries} = :zip.unzip(zip, [:memory])

        entries
      end
    end
  end

  describe "&convert!/2" do
    for filename <- @fixtures do
      {format, fixture_name} = ReaderSnapshots.parse_path(filename)

      test_snapshot "successfully converts #{format}/#{fixture_name}" do
        DateTime
        |> expect(:utc_now, fn -> ~U[1970-01-01 00:00:00Z] end)

        {:ok, path} = Briefly.create(extname: ".epub")

        on_exit(fn -> File.rm(path) end)

        spec =
          %DocumentSpecification{document: %Document{}} =
          unquote(filename)
          |> File.read!()
          |> Jason.decode!()
          |> Schema.decode_keys()
          |> DocumentSpecification.new!()

        :ok = Writer.convert!(spec, path)

        assert File.exists?(path)

        {:ok, zip} = File.read(path)
        {:ok, entries} = :zip.unzip(zip, [:memory])

        entries
      end
    end
  end
end
