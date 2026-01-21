# DocSpec

A document specification and conversion library for Elixir.

DocSpec provides a universal document representation with readers and writers for multiple formats, enabling document conversion while preserving semantic structure and accessibility.

## Features

**Readers** (parse into DocSpec):
- DOCX (Microsoft Word)
- Tiptap JSON

**Writers** (generate from DocSpec):
- HTML (accessible, semantic)
- EPUB
- Tiptap JSON
- BlockNote JSON

**Validation**:
- Accessibility rules (alt text, heading structure, etc.)
- Document structure validation

## Installation

Add `docspec` to your dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:docspec, "~> 1.1"}
  ]
end
```

## Requirements

- Elixir ~> 1.18
- OTP >= 25 (OTP >= 27 highly recommended for EPUB conformity)

We roughly follow [Elixir's support cycle](https://hexdocs.pm/elixir/compatibility-and-deprecations.html) for Elixir and OTP version support.

## Usage

### Convert DOCX to HTML

```elixir
{:ok, spec} = DocSpec.Core.DOCX.Reader.read("document.docx")
html = DocSpec.Core.HTML.Writer.convert(spec)
```

### Convert DOCX to EPUB

```elixir
{:ok, spec} = DocSpec.Core.DOCX.Reader.read("document.docx")
{:ok, epub_binary} = DocSpec.Core.EPUB.Writer.convert!(spec)
File.write!("document.epub", epub_binary)
```

### Convert Tiptap to BlockNote

```elixir
{:ok, spec} = DocSpec.Core.Tiptap.Reader.convert(tiptap_json)
{:ok, blocknote} = DocSpec.Core.BlockNote.Writer.write(spec, [])
```

### Validate a document

```elixir
{:ok, spec} = DocSpec.Core.DOCX.Reader.read("document.docx")
findings = DocSpec.Core.Validation.Writer.validate(spec)
```

## Command-Line Interface

DocSpec includes a CLI for document conversion, available as both an escript (requires Erlang/OTP) and native binaries (standalone, no dependencies).

### Pre-built Binaries

Download standalone binaries from [GitHub Releases](https://github.com/docspec/docspec-ex/releases). Available for:

- Linux x86_64 (glibc and musl)
- Linux aarch64 (glibc and musl)
- macOS x86_64
- macOS aarch64 (Apple Silicon)
- Windows x86_64

### Building from Source

**Escript** (requires Erlang/OTP on target system):

```bash
mix escript.build
```

**Native binaries** (standalone, via [Burrito](https://github.com/burrito-elixir/burrito)):

```bash
MIX_ENV=prod mix deps.get
BURRITO_BUILD=1 MIX_ENV=prod mix release
```

Binaries are output to `burrito_out/`.

### CLI Usage

```bash
docspec convert -i INPUT -o OUTPUT [OPTIONS]
docspec --version
docspec --help
```

**Options:**

| Option | Description |
|--------|-------------|
| `-i, --input FILE` | Input file (required) |
| `-o, --output FILE` | Output file (required) |
| `-I, --input-format FORMAT` | Override input format: `docx`, `tiptap` |
| `-f, --format FORMAT` | Override output format: `html`, `epub`, `tiptap`, `blocknote` |

### CLI Examples

```bash
# Convert DOCX to HTML
docspec convert -i document.docx -o output.html

# Convert DOCX to EPUB
docspec convert -i document.docx -o book.epub

# Convert DOCX to BlockNote JSON
docspec convert -i document.docx -o output.json --format blocknote

# Convert Tiptap JSON to HTML
docspec convert -i content.json -o output.html --input-format tiptap
```

### Format Detection

Formats are automatically detected by file extension:

| Extension | Input Format | Output Format |
|-----------|--------------|---------------|
| `.docx` | DOCX | - |
| `.json` | Tiptap | Tiptap |
| `.html`, `.htm` | - | HTML |
| `.epub` | - | EPUB |

Use `--input-format` or `--format` to override detection when needed.

## Documentation

Documentation is available at [HexDocs](https://hexdocs.pm/docspec).

## License

Licensed under the [EUPL-1.2](LICENSE).
