defmodule DocSpec.Util.State do
  @moduledoc """
  This module defines a macro for defining a struct that captures the state during a conversion.

  ## Usage

  ```ex
  module State do
    use DocSpec.Util.State

    schema do
      field :example, String.t(), default: "Hello"
      field :foo, integer() | nil # Infers has default `nil`
      field :bar, [String.t() | integer()] # Infers has default `[]`
    end
  end
  ```
  """

  defmacro __using__(_opts) do
    quote do
      import DocSpec.Util.State, only: [schema: 1, field: 2, field: 3]

      Module.register_attribute(__MODULE__, :state_fields, accumulate: true)
    end
  end

  # coveralls-ignore-start These macros cannot be covered by ExCoveralls

  def field(_, _, _), do: nil
  def field(_, _), do: nil

  defp infer_default([_elem_type]), do: {:ok, []}
  defp infer_default({:%{}, _, _}), do: {:ok, {:%{}, [], []}}
  defp infer_default(nil), do: {:ok, nil}

  defp infer_default({:|, _, [left, right]}) do
    case infer_default(left) do
      {:ok, left_default} ->
        left_default

      :error ->
        infer_default(right)
    end
  end

  defp infer_default(_), do: :error

  defp infer_default!(name, typespec) do
    case infer_default(typespec) do
      {:ok, default} ->
        default

      :error ->
        raise [
                "Inferring default value for :#{name} with is not supported.",
                "Typespec:",
                inspect(typespec, pretty: true)
              ]
              |> Enum.join("\n\n")
    end
  end

  defp get_field_data({:field, _meta, [name, typespec]}),
    do: get_field_data({:field, [], [name, typespec, []]})

  defp get_field_data({:field, _meta, [name, typespec, opts]}) do
    default =
      if Keyword.has_key?(opts, :default) do
        opts |> Keyword.get(:default)
      else
        name |> infer_default!(typespec)
      end

    %{
      name: name,
      typespec: typespec,
      default: default,
      enforced?: opts |> Keyword.get(:enforced?, false)
    }
  end

  defp list_type?({:|, _, [left, right]}), do: list_type?(left) or list_type?(right)
  defp list_type?({:list, _, [_elem_type]}), do: true
  defp list_type?([_elem_type]), do: true
  defp list_type?(_), do: false

  # For example: [String.t()] | [number()] becomes String.t() | number()

  defp unwrap_list_type({:|, _, [left, right]}),
    do: {:|, [], [unwrap_list_type(left), unwrap_list_type(right)]}

  defp unwrap_list_type({:list, _, [elem_type]}),
    do: elem_type

  defp unwrap_list_type([elem_type]),
    do: elem_type

  defp prepend_methods(fields_data) do
    for %{name: name, typespec: typespec} <- fields_data, list_type?(typespec) do
      quote do
        # Prepend a list of items to the list
        @spec prepend(t, unquote(name), unquote(typespec)) :: t
        def prepend(state = %__MODULE__{}, unquote(name), values)
            when is_list(values),
            do: state |> set(unquote(name), values ++ get(state, unquote(name)))

        # Prepend a single item to the list
        @spec prepend(t, unquote(name), unquote(unwrap_list_type(typespec))) :: t
        def prepend(state = %__MODULE__{}, unquote(name), value)
            when not is_list(value),
            do: state |> set(unquote(name), [value | get(state, unquote(name))])
      end
    end
  end

  defp set_methods(fields_data) do
    for %{name: name, typespec: typespec} <- fields_data do
      quote do
        @spec set(t, unquote(name), unquote(typespec)) :: t
        def set(state = %__MODULE__{}, unquote(name), value),
          do: state |> Map.put(unquote(name), value)
      end
    end
  end

  defp get_methods(fields_data) do
    for %{name: name, typespec: typespec} <- fields_data do
      quote do
        @spec get(t, unquote(name)) :: unquote(typespec)
        def get(state = %__MODULE__{}, unquote(name)),
          do: state |> Map.get(unquote(name))
      end
    end
  end

  defp keep_methods(fields_data) do
    for %{name: name} <- fields_data do
      quote do
        @spec keep(t, t, unquote(name)) :: t
        def keep(new_state = %__MODULE__{}, old_state = %__MODULE__{}, unquote(name)),
          do: new_state |> Map.put(unquote(name), old_state |> Map.get(unquote(name)))
      end
    end
  end

  defmacro schema(do: ast) do
    fields_ast =
      case ast do
        {:__block__, [], fields} -> fields
        field -> [field]
      end

    fields_data = fields_ast |> Enum.map(&get_field_data/1)

    enforced_fields =
      for field <- fields_data, field.enforced? do
        field.name
      end

    typespecs =
      Enum.map(fields_data, fn
        %{name: name, typespec: typespec, enforced?: true} ->
          {name, typespec}

        %{name: name, typespec: typespec} ->
          {
            name,
            {:|, [], [typespec, nil]}
          }
      end)

    fields =
      for %{name: name, default: default} <- fields_data do
        {name, default}
      end

    field_names =
      fields_data
      |> Enum.map_join(", ", fn %{name: name} -> ":" <> Atom.to_string(name) end)

    list_field_names =
      fields_data
      |> Enum.filter(fn %{typespec: typespec} -> list_type?(typespec) end)
      |> Enum.map_join(", ", fn %{name: name} -> ":" <> Atom.to_string(name) end)

    # coveralls-ignore-stop

    quote location: :keep do
      @type t :: %__MODULE__{unquote_splicing(typespecs)}
      @enforce_keys unquote(enforced_fields)
      defstruct unquote(fields)

      @doc """
      Gets the given field from the state object.

      This function only accepts fields of the state, which are #{unquote(field_names)}.
      It will raise if the field is not valid.
      """
      unquote_splicing(get_methods(fields_data))

      @doc """
      Sets the given field on the state object to the given value.

      This function only accepts fields of the state, which are #{unquote(field_names)}.
      It will raise if the field is not valid.
      """
      unquote_splicing(set_methods(fields_data))

      @doc """
      Modifies a state object by setting the given field to the value that field had in the old state.

      This function only accepts fields of the state, which are #{unquote(field_names)}.
      It will raise if the field is not valid.
      """
      unquote_splicing(keep_methods(fields_data))

      @doc """
      Prepends a list of values or a single value to the list field in the state object.

      This function only accepts fields of the state, which are #{unquote(list_field_names)}.
      It will raise if the field is not valid.
      """
      unquote_splicing(prepend_methods(fields_data))
    end
  end
end
