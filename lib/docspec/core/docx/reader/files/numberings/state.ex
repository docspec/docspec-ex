defmodule DocSpec.Core.DOCX.Reader.Files.Numberings.State do
  @moduledoc """
  This module defines a struct that captures the state of the converter during a Docx conversion.
  """

  alias DocSpec.Core.DOCX.Reader.AST

  use DocSpec.Util.State

  schema do
    field :abstract_numberings, [AST.Numbering.t()]
    field :numberings, [AST.Numbering.t()]
    field :level, integer() | nil
    field :abstract_numbering_id, String.t() | nil
    field :numbering_id, String.t() | nil
  end
end
