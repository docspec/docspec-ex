defmodule DocSpec.Core.DOCX.Reader.Files.ContentTypes do
  @moduledoc """
  Parsing for the "[Content_Types].xml" file inside a Docx document.
  """

  alias DocSpec.Core.DOCX.Reader.Files.ContentTypes

  defstruct defaults: %{}, overrides: %{}

  @type t :: %__MODULE__{
          # maps extensions to content types
          defaults: %{String.t() => String.t()},
          # maps relative filenames (starting with /) to content types
          overrides: %{String.t() => String.t()}
        }

  @doc """
  Parses the contents of a `[Content_Types].xml` file into a `ContentTypes` struct.
  """
  @spec parse(Saxy.XML.element()) :: t()
  def parse({"Types", _, children}) do
    Enum.reduce(children, %ContentTypes{}, fn
      {"Default", attrs, _}, types = %ContentTypes{defaults: defaults} ->
        extension = attrs |> SimpleForm.Attrs.get_value("Extension")
        content_type = attrs |> SimpleForm.Attrs.get_value("ContentType")
        %ContentTypes{types | defaults: Map.put(defaults, extension, content_type)}

      {"Override", attrs, _}, types = %ContentTypes{overrides: overrides} ->
        filename = attrs |> SimpleForm.Attrs.get_value("PartName")
        content_type = attrs |> SimpleForm.Attrs.get_value("ContentType")
        %ContentTypes{types | overrides: Map.put(overrides, filename, content_type)}

      _, this ->
        this
    end)
  end

  @doc """
  Returns the content type for a given filename.

  ## Examples

      iex> content_types = %ContentTypes{
      ...>   defaults: %{
      ...>     "txt" => "text/plain",
      ...>     "xml" => "application/xml"
      ...>   },
      ...>   overrides: %{
      ...>     "/document.xml" => "application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"
      ...>   }
      ...> }
      iex> content_types |> ContentTypes.type("/some/file.txt")
      "text/plain"
      iex> content_types |> ContentTypes.type("/file.xml")
      "application/xml"
      iex> content_types |> ContentTypes.type("/document.xml")
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"
  """
  def type(%ContentTypes{defaults: defaults, overrides: overrides}, filename) do
    case overrides[filename] do
      nil -> defaults[filename |> Path.extname() |> String.trim_leading(".")]
      content_type -> content_type
    end
  end
end
