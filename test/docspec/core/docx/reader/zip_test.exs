defmodule DocSpec.Core.DOCX.Reader.ZipTest do
  @moduledoc false
  use ExUnit.Case
  use Mimic

  alias DocSpec.Core.DOCX.Reader.Zip

  @test_files ["test_file1.txt", "test_file2.txt"]
  @output_zip_path "test_output.zip"
  @extraction_path "extracted_files"

  setup_all do
    # Create test files
    Enum.each(@test_files, fn file ->
      File.write!(file, "This is a test file.")
    end)

    # Clean up test files and directories
    on_exit(fn ->
      Enum.each(@test_files, &File.rm/1)
      File.rm(@output_zip_path)
      File.rm_rf(@extraction_path)
    end)

    :ok
  end

  test "create/2 creates a zip file from a list of files" do
    assert :ok == Zip.create(@test_files, @output_zip_path)
    assert File.exists?(@output_zip_path)
  end

  test "create/2 returns an error if any file does not exist" do
    message = "cannot create zip: these files do not exist: non_existing_file.txt"

    assert {:error, %ArgumentError{message: message}} ==
             Zip.create(@test_files ++ ["non_existing_file.txt"], @output_zip_path)
  end

  test "create/2 returns an error when :zip returns an error" do
    assert {:error, :enoent} = Zip.create(@test_files, "")
  end

  test "extract/2 extracts a zip file created by create/2 to a directory" do
    assert :ok == Zip.create(@test_files, @output_zip_path)
    assert :ok == Zip.extract(@output_zip_path, @extraction_path)

    Enum.each(@test_files, fn file ->
      assert File.exists?(Path.join(@extraction_path, file))
    end)
  end

  test "extract/2 returns an error if the zip file does not exist" do
    assert {:error, %ArgumentError{message: "cannot find zip file non_existing.zip"}} =
             Zip.extract("non_existing.zip", @extraction_path)
  end

  test "extract/2 returns an error if the extraction path cannot be created" do
    expect(File, :exists?, 1, fn @output_zip_path -> true end)
    expect(File, :mkdir_p!, 1, fn @extraction_path -> raise %File.Error{reason: :eacces} end)

    assert {:error, %File.Error{reason: :eacces}} =
             Zip.extract(@output_zip_path, @extraction_path)
  end

  test "extract/2 returns an error when :zip returns an error" do
    expect(File, :exists?, 1, fn _ -> true end)
    expect(File, :mkdir_p!, 1, fn _ -> :ok end)
    assert {:error, :enoent} = Zip.extract("totally-non-existant", "nowhere")
  end
end
