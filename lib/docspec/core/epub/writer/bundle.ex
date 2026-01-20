defmodule DocSpec.Core.EPUB.Writer.Bundle do
  @moduledoc """
  Represents a complete EPUB bundle containing all required components.

  An EPUB bundle aggregates all the pieces needed to create a valid EPUB file:
  - Package metadata (OPF file)
  - Document content (XHTML chapter)
  - Navigation XHTML (nav.xhtml)
  - Legacy NCX navigation (toc.ncx for EPUB 2 compatibility)

  This struct is typically passed to `DocSpec.Core.EPUB.Writer.ZIP` to
  generate the final EPUB archive.

  ## Fields

  - `:package` - The package metadata and manifest (OPF file)
  - `:document` - The main document content as XHTML
  - `:nav_xhtml` - Navigation document in XHTML format
  - `:nav_ncx` - Navigation document in NCX format (legacy)
  """

  alias DocSpec.Core.EPUB.Writer, as: EPUB
  alias DocSpec.Spec.Asset

  use TypedStruct

  typedstruct enforce: true do
    field :package, EPUB.Package.t()
    field :document, EPUB.XHTML.t()
    field :nav_xhtml, EPUB.XHTML.t()
    field :nav_ncx, EPUB.TableOfContents.ncx()
    field :assets, [Asset.t()]
  end
end
