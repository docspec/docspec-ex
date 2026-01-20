defmodule DocSpec.Core.EPUB.Writer.ZipTest do
  @moduledoc false

  use ExUnit.Case, async: false
  use Mimic

  import Exposure

  doctest DocSpec.Core.EPUB.Writer.ZIP

  alias DocSpec.Core.EPUB.Writer, as: EPUB

  setup do
    # Unstick the :zip module directory to allow mocking
    stdlib_dir = :code.lib_dir(:stdlib) ++ ~c"/ebin"
    :code.unstick_dir(stdlib_dir)
    Mimic.copy(:zip)
    on_exit(fn -> :code.stick_dir(stdlib_dir) end)

    :ok
  end

  describe "write!/2" do
    test "returns error when writing to nonexistent directory" do
      bundle = %EPUB.Bundle{
        package: {"package", [], []},
        document: {"html", [], []},
        nav_xhtml: {"nav", [], []},
        nav_ncx: {"ncx", [], []},
        assets: []
      }

      :zip
      |> expect(:create, fn _path, _entries, _opts ->
        {:error, :enoent}
      end)

      assert {:error, :enoent} = EPUB.ZIP.write!(bundle, "/nonexistent/directory/file.epub")
    end
  end

  describe "write!/1" do
    test "handles Saxy encoding errors" do
      # Create a bundle with invalid XML that will cause Saxy.encode! to fail
      invalid_bundle = %EPUB.Bundle{
        package: {:invalid, :structure},
        document: {:invalid, :structure},
        nav_xhtml: {:invalid, :structure},
        nav_ncx: {:invalid, :structure},
        assets: []
      }

      assert_raise FunctionClauseError, fn ->
        EPUB.ZIP.write!(invalid_bundle)
      end
    end

    test_snapshot "successfully creates zip in memory with valid bundle" do
      bundle = %EPUB.Bundle{
        package: {"package", [], []},
        document: {"html", [], []},
        nav_xhtml: {"nav", [], []},
        nav_ncx: {"ncx", [], []},
        assets: []
      }

      assert {:ok, zip} = EPUB.ZIP.write!(bundle)
      assert is_binary(zip)

      {:ok, entries} = :zip.unzip(zip, [:memory])

      entries
    end

    test "returns error when zip creation fails in memory" do
      bundle = %EPUB.Bundle{
        package: {"package", [], []},
        document: {"html", [], []},
        nav_xhtml: {"nav", [], []},
        nav_ncx: {"ncx", [], []},
        assets: []
      }

      :zip
      |> expect(:create, fn ~c"mem", _entries, _opts ->
        {:error, :emem}
      end)

      assert {:error, :emem} = EPUB.ZIP.write!(bundle)
    end
  end
end
