defmodule DocSpec.Core.DOCX.Reader.Zip do
  @moduledoc """
  This module implements some helper functions for handling `.zip` files.
  """

  @doc """
  Create a `.zip` file from a list of files.

  The first argument should be a list of paths to the files that should be included in the `.zip` file.
  It is highly recommended to use absolute paths, though paths relative to the application's CWD will work as well.

  The second argument should be the path to the `.zip` file that should be created.
  """

  @spec create!([String.t()], String.t()) :: :ok
  def create!(files, output_zip_path) when is_list(files) and is_binary(output_zip_path) do
    assert_all_files_exist(files)

    result =
      output_zip_path
      |> String.to_charlist()
      |> :zip.create(Enum.map(files, &String.to_charlist/1))

    case result do
      {:ok, _} -> :ok
      {:error, error} -> throw(error)
    end
  end

  @spec create([String.t()], String.t()) ::
          {:ok, :done} | {:error, atom() | String.t() | Exception.t()}
  def create(files, output_zip_path) do
    create!(files, output_zip_path)
  rescue
    error -> {:error, error}
  catch
    error -> {:error, error}
  end

  @doc """
  Extract a `.zip` file to a directory. The first argument should be the path to the `.zip` file to extract.
  The second argument should be the path to the directory where the contents of the `.zip` file will be extracted to.
  If this directory does not yet exist, it will be created.

  This function will raise an error if the `.zip` file does not exist, if the extraction path cannot be created,
  or if the extraction fails. If you prefer an error tuple instead, use `extract/2`.
  """
  @spec extract!(String.t(), String.t()) :: :ok
  def extract!(archive_path, extraction_path)
      when is_binary(archive_path) and is_binary(extraction_path) do
    if not File.exists?(archive_path) do
      raise ArgumentError, message: "cannot find zip file #{archive_path}"
    end

    File.mkdir_p!(extraction_path)

    result =
      archive_path
      |> String.to_charlist()
      |> :zip.extract(cwd: extraction_path |> String.to_charlist())

    case result do
      {:ok, _} -> :ok
      {:error, error} -> throw(error)
    end
  end

  @spec extract(String.t(), String.t()) :: :ok | {:error, atom() | String.t() | Exception.t()}
  def extract(archive_path, extraction_path) do
    extract!(archive_path, extraction_path)
  rescue
    error -> {:error, error}
  catch
    error -> {:error, error}
  end

  defp assert_all_files_exist(files) do
    non_existing_files = Enum.reject(files, &File.exists?/1)

    if not Enum.empty?(non_existing_files) do
      message =
        "cannot create zip: these files do not exist: #{Enum.join(non_existing_files, ", ")}"

      raise ArgumentError, message: message
    end
  end
end
