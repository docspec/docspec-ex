defmodule DocSpec.Core.BlockNote.Spec do
  @moduledoc """
  Base module for BlockNote spec structs.

  Use this instead of `use TypedStruct` to get automatic JSON encoding with camelCase keys.

      defmodule MyBlock do
        use DocSpec.Core.BlockNote.Spec

        typedstruct enforce: true do
          field :id, String.t()
          field :type, :myBlock, default: :myBlock
        end
      end

  Then `Jason.encode!/1` just works with camelCase keys.
  """

  defmacro __using__(_opts) do
    quote do
      use TypedStruct
      @before_compile DocSpec.Core.BlockNote.Spec
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      defimpl Jason.Encoder, for: __MODULE__ do
        def encode(struct, opts) do
          struct
          |> DocSpec.JSON.to_map()
          |> Jason.Encode.map(opts)
        end
      end
    end
  end
end
