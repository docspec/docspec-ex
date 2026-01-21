# DocSpec

A document specification and conversion library for Elixir.

DocSpec provides a universal document representation with readers and writers for multiple formats, enabling document conversion while preserving semantic structure and accessibility.

## Usage

This application can be used as an Elixir libray or directly on the command line.

### CLI (Command-Line)

DocSpec includes a CLI for document conversion, available as both an escript (requires Erlang/OTP) and native binaries (standalone, no dependencies).

```bash
# Convert DOCX to HTML
$ docspec convert -i document.docx -o output.html

# Convert DOCX to EPUB
$ docspec convert -i document.docx -o book.epub

# Convert DOCX to BlockNote JSON
$ docspec convert -i document.docx -o output.json --format blocknote

# Convert Tiptap JSON to HTML
$ docspec convert -i content.json -o output.html --input-format tiptap
```

### Installation

#### Arch Linux (AUR)

```bash
$ paru -S docspec-bin
# or with yay: yay -S docspec-bin
```

#### Pre-built Binaries

Download standalone binaries from [GitHub Releases](https://github.com/docspec/docspec-ex/releases). Available for:

- Linux x86_64 (glibc and musl)
- Linux aarch64 (glibc and musl)
- macOS x86_64
- macOS aarch64 (Apple Silicon)
- Windows x86_64

#### Building from Source

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

## Library

### Installation

Add `docspec` to your dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:docspec, "~> 1.3"}
  ]
end
```

**Requirements:**

- Elixir ~> 1.18
- OTP >= 25 (OTP >= 27 highly recommended for EPUB conformity)

We roughly follow [Elixir's support cycle](https://hexdocs.pm/elixir/compatibility-and-deprecations.html) for Elixir and OTP version support.

### Examples

#### Convert DOCX to HTML

```elixir
{:ok, spec} = DocSpec.Core.DOCX.Reader.read("document.docx")
html = DocSpec.Core.HTML.Writer.convert(spec)
```

#### Convert DOCX to EPUB

```elixir
{:ok, spec} = DocSpec.Core.DOCX.Reader.read("document.docx")
{:ok, epub_binary} = DocSpec.Core.EPUB.Writer.convert!(spec)
File.write!("document.epub", epub_binary)
```

#### Convert Tiptap to BlockNote

```elixir
{:ok, spec} = DocSpec.Core.Tiptap.Reader.convert(tiptap_json)
{:ok, blocknote} = DocSpec.Core.BlockNote.Writer.write(spec, [])
```

#### Validate a document

```elixir
{:ok, spec} = DocSpec.Core.DOCX.Reader.read("document.docx")
findings = DocSpec.Core.Validation.Writer.validate(spec)
```

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

## Documentation

Documentation is available at [HexDocs](https://hexdocs.pm/docspec).

## License

Licensed under the [EUPL-1.2](LICENSE).
