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
    {:docspec, "~> 0.1"}
  ]
end
```

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

## Documentation

Documentation is available at [HexDocs](https://hexdocs.pm/docspec).

## License

Licensed under the [EUPL-1.2](LICENSE).
