defmodule DocSpec.CLI do
  @moduledoc """
  Command-line interface for DocSpec document conversion.

  ## Usage

      docspec convert -i INPUT -o OUTPUT [--format FORMAT]
      docspec --version
      docspec --help

  ## Examples

      # Convert DOCX to HTML
      docspec convert -i document.docx -o output.html

      # Convert DOCX to EPUB
      docspec convert -i document.docx -o book.epub

      # Convert Tiptap JSON to HTML
      docspec convert -i content.json -o output.html --input-format tiptap

      # Convert DOCX to BlockNote JSON
      docspec convert -i document.docx -o output.json --format blocknote

  ## Exit Codes

  - 0: Success
  - 1: General error
  - 2: Input file not found
  - 3: Unsupported format
  - 4: Conversion error
  """

  @version Mix.Project.config()[:version]

  @input_formats ~w(docx tiptap)
  @output_formats ~w(html epub tiptap blocknote)

  @doc """
  Main entry point for the CLI.
  """
  @spec main([String.t()]) :: no_return()
  def main(args) do
    args
    |> parse_args()
    |> run()
  end

  @spec parse_args([String.t()]) ::
          {:convert, keyword()}
          | :help
          | :version
          | {:error, String.t()}
  defp parse_args(args) do
    case args do
      ["convert" | rest] -> parse_convert_args(rest)
      ["--version"] -> :version
      ["-v"] -> :version
      ["--help"] -> :help
      ["-h"] -> :help
      [] -> :help
      _ -> {:error, "Unknown command. Use --help for usage information."}
    end
  end

  @spec parse_convert_args([String.t()]) :: {:convert, keyword()} | {:error, String.t()}
  defp parse_convert_args(args) do
    {opts, _rest, invalid} =
      OptionParser.parse(args,
        strict: [
          input: :string,
          output: :string,
          format: :string,
          input_format: :string,
          help: :boolean
        ],
        aliases: [
          i: :input,
          o: :output,
          f: :format,
          I: :input_format,
          h: :help
        ]
      )

    cond do
      opts[:help] ->
        :help

      invalid != [] ->
        {flag, _} = hd(invalid)
        {:error, "Unknown option: #{flag}"}

      is_nil(opts[:input]) ->
        {:error, "Missing required option: --input (-i)"}

      is_nil(opts[:output]) ->
        {:error, "Missing required option: --output (-o)"}

      true ->
        {:convert, opts}
    end
  end

  @spec run(:help | :version | {:convert, keyword()} | {:error, String.t()}) :: no_return()
  defp run(:help) do
    IO.puts("""
    DocSpec - Document conversion tool

    USAGE:
        docspec convert -i INPUT -o OUTPUT [OPTIONS]
        docspec --version
        docspec --help

    COMMANDS:
        convert    Convert a document from one format to another

    OPTIONS:
        -i, --input FILE           Input file (required)
        -o, --output FILE          Output file (required)
        -I, --input-format FORMAT  Override input format detection
                                   Formats: #{Enum.join(@input_formats, ", ")}
        -f, --format FORMAT        Override output format detection
                                   Formats: #{Enum.join(@output_formats, ", ")}
        -h, --help                 Show this help message
        -v, --version              Show version

    FORMAT DETECTION:
        Input formats are detected by file extension:
            .docx  -> DOCX
            .json  -> Tiptap (use --input-format for others)

        Output formats are detected by file extension:
            .html  -> HTML
            .epub  -> EPUB
            .json  -> Tiptap (use --format for blocknote)

    EXAMPLES:
        docspec convert -i document.docx -o output.html
        docspec convert -i document.docx -o book.epub
        docspec convert -i content.json -o output.html -I tiptap
        docspec convert -i document.docx -o output.json -f blocknote
    """)

    System.halt(0)
  end

  defp run(:version) do
    IO.puts("docspec #{@version}")
    System.halt(0)
  end

  defp run({:error, message}) do
    IO.puts(:stderr, "Error: #{message}")
    System.halt(1)
  end

  defp run({:convert, opts}) do
    input_path = opts[:input]
    output_path = opts[:output]

    with :ok <- validate_input_file(input_path),
         {:ok, input_format} <- detect_input_format(input_path, opts[:input_format]),
         {:ok, output_format} <- detect_output_format(output_path, opts[:format]),
         {:ok, spec} <- read_input(input_path, input_format),
         :ok <- write_output(spec, output_path, output_format) do
      IO.puts("Successfully converted #{input_path} to #{output_path}")
      System.halt(0)
    else
      {:error, :file_not_found} ->
        IO.puts(:stderr, "Error: Input file not found: #{input_path}")
        System.halt(2)

      {:error, {:unsupported_format, format}} ->
        IO.puts(:stderr, "Error: Unsupported format: #{format}")
        System.halt(3)

      {:error, {:conversion_error, reason}} ->
        IO.puts(:stderr, "Error: Conversion failed: #{inspect(reason)}")
        System.halt(4)

      {:error, reason} ->
        IO.puts(:stderr, "Error: #{inspect(reason)}")
        System.halt(1)
    end
  end

  @spec validate_input_file(String.t()) :: :ok | {:error, :file_not_found}
  defp validate_input_file(path) do
    if File.exists?(path) do
      :ok
    else
      {:error, :file_not_found}
    end
  end

  @spec detect_input_format(String.t(), String.t() | nil) ::
          {:ok, atom()} | {:error, {:unsupported_format, String.t()}}
  defp detect_input_format(_path, format) when format in @input_formats,
    do: {:ok, String.to_atom(format)}

  defp detect_input_format(_path, format) when is_binary(format),
    do: {:error, {:unsupported_format, format}}

  defp detect_input_format(path, nil) do
    case Path.extname(path) |> String.downcase() do
      ".docx" -> {:ok, :docx}
      ".json" -> {:ok, :tiptap}
      ext -> {:error, {:unsupported_format, ext}}
    end
  end

  @spec detect_output_format(String.t(), String.t() | nil) ::
          {:ok, atom()} | {:error, {:unsupported_format, String.t()}}
  defp detect_output_format(_path, format) when format in @output_formats,
    do: {:ok, String.to_atom(format)}

  defp detect_output_format(_path, format) when is_binary(format),
    do: {:error, {:unsupported_format, format}}

  defp detect_output_format(path, nil) do
    case Path.extname(path) |> String.downcase() do
      ".html" -> {:ok, :html}
      ".htm" -> {:ok, :html}
      ".epub" -> {:ok, :epub}
      ".json" -> {:ok, :tiptap}
      ext -> {:error, {:unsupported_format, ext}}
    end
  end

  @spec read_input(String.t(), atom()) ::
          {:ok, DocSpec.Spec.DocumentSpecification.t()} | {:error, term()}
  defp read_input(path, :docx) do
    reader = DocSpec.Core.DOCX.Reader.open!(path)

    try do
      {:ok, DocSpec.Core.DOCX.Reader.convert!(reader)}
    rescue
      e -> {:error, {:conversion_error, e}}
    after
      DocSpec.Core.DOCX.Reader.close!(reader)
    end
  end

  defp read_input(path, :tiptap) do
    with {:ok, content} <- File.read(path),
         {:ok, json} <- Jason.decode(content, keys: :atoms),
         {:ok, spec} <- DocSpec.Core.Tiptap.Reader.convert(json) do
      {:ok, spec}
    else
      {:error, %Jason.DecodeError{} = e} ->
        {:error, {:conversion_error, "Invalid JSON: #{Exception.message(e)}"}}

      {:error, reason} ->
        {:error, {:conversion_error, reason}}
    end
  end

  @spec write_output(DocSpec.Spec.DocumentSpecification.t(), String.t(), atom()) ::
          :ok | {:error, term()}
  defp write_output(spec, path, :html) do
    html = DocSpec.Core.HTML.Writer.convert(spec)
    File.write(path, html)
  end

  defp write_output(spec, path, :epub) do
    case DocSpec.Core.EPUB.Writer.convert!(spec, path) do
      :ok -> :ok
      {:error, reason} -> {:error, {:conversion_error, reason}}
    end
  end

  defp write_output(spec, path, :tiptap) do
    case DocSpec.Core.Tiptap.Writer.convert(spec) do
      {:ok, tiptap} ->
        json = Jason.encode!(tiptap, pretty: true)
        File.write(path, json)

      {:error, reason} ->
        {:error, {:conversion_error, reason}}
    end
  end

  defp write_output(spec, path, :blocknote) do
    case DocSpec.Core.BlockNote.Writer.write(spec) do
      {:ok, blocknote} ->
        json = Jason.encode!(blocknote, pretty: true)
        File.write(path, json)

      {:error, reason} ->
        {:error, {:conversion_error, reason}}
    end
  end
end
