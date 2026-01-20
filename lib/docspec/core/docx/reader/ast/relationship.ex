defmodule DocSpec.Core.DOCX.Reader.AST.Relationship do
  @moduledoc """
  This module defines a struct that represents a relationship in a Word document
  as found in files like `word/_rels/document.xml`.
  """

  @type t :: %__MODULE__{
          id: String.t(),
          type: String.t(),
          target: String.t(),
          target_mode: String.t() | nil
        }
  @fields [:id, :type, :target, :target_mode]
  @enforce_keys @fields
  defstruct @fields
end
