defmodule DocSpec.Core.Validation.Writer.State do
  @moduledoc """
  State for validation rules.
  """

  alias DocSpec.Core.Validation.Spec.Finding

  use DocSpec.Util.State

  schema do
    field :findings, [Finding.t()]
    field :heading_level, :infinity | integer(), default: :infinity
    field :definition_term_id_without_details, String.t() | nil
    field :encountered_heading_1?, boolean(), default: false
    field :parent_is_heading?, boolean(), default: false
  end
end
