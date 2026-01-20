defmodule DocSpec.Core.DOCX.Reader do
  @moduledoc """
  The `DocSpec.Core.DOCX.Reader` struct represents an opened DOCX file.

  This module provides functions for opening, converting and reading from DOCX files.

  Note: after opening a DOCX file with `open!/1`, it is highly recommended to call `close!/1`
  to clean up the temporary directory in which the DOCX file was extracted.

  ## Package Structure

  The `DocSpec.Core.DOCX.Reader` package is structured as follows:

  - `DocSpec.Core.DOCX.Reader`: contains the main `DOCX` struct and functions for opening and closing DOCX files.
                             `convert!/1` is delegated to `DocSpec.Core.DOCX.Reader.Convert`.
  - `DocSpec.Core.DOCX.Reader.AST`: implements structures that represent the information contained in the files of a DOCX document.
                                 This is our Abstract Syntax Tree (AST), our internal representation of the contents of everything in a DOCX document.
  - `DocSpec.Core.DOCX.Reader.Files`: implements everything related to what files are in a DOCX document:
                                   `[Content_Types].xml`, `docProps/core.xml`, `document.xml`, `numbering.xml`,
                                   `styles.xml`, `.rels` files etc.
  - `DocSpec.Core.DOCX.Reader.Convert`: implements the actual conversion of AST to DocSpec Spec.
  """

  alias DocSpec.Core.DOCX.Reader
  alias DocSpec.Core.DOCX.Reader.Files
  alias DocSpec.Core.DOCX.Reader.Zip

  @type t :: %__MODULE__{
          files: Files.t(),
          core_properties: Files.CoreProperties.t(),
          document: Files.Document.t(),
          numberings: Files.Numberings.t(),
          styles: Files.Styles.t()
        }

  @fields [:files, :core_properties, :document, :numberings, :styles]
  @enforce_keys @fields
  defstruct @fields

  @doc """
  Open a DOCX file and extract its contents to a temporary directory, raising errors when any of these steps fail.
  Returns a `DOCX` struct that can be used with the rest of the functions in this module.
  When you're done with the `DOCX` struct, you should call `close!/1` to clean up the temporary directory.
  """
  @spec open!(String.t()) :: Reader.t()
  def open!(filepath) do
    dir = Temp.path!()
    File.mkdir_p!(dir)
    Zip.extract!(filepath, dir)

    files = Files.read(dir)

    %Reader{
      files: files,
      core_properties: files |> Files.core_properties() |> Files.CoreProperties.read!(),
      document: files |> Files.document() |> Files.Document.read!(files),
      numberings: files |> Files.numberings() |> Files.Numberings.read!(),
      styles: files |> Files.styles() |> Files.Styles.read!()
    }
  end

  @doc """
  Close a `DOCX` struct, removing the temporary directory in which the DOCX file was extracted.
  After this, the `DOCX` struct can no longer be used as input to any functions in this module.
  """
  @spec close!(Reader.t()) :: :ok
  def close!(%Reader{files: %Files{dir: dir}}) do
    File.rm_rf!(dir)
    :ok
  end

  defdelegate convert!(docx), to: Reader.Convert, as: :convert
end
