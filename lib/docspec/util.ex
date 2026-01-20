defmodule DocSpec.Util do
  @moduledoc """
  `DocSpec.Util` implements utility functions that are used throughout the project,
  but don't fit into any of the other modules.
  """

  @doc """
  Returns the new value if it is not nil, otherwise returns the default value.

  ## Examples

      iex> DocSpec.Util.default(nil, 1)
      1
      iex> DocSpec.Util.default(2, 1)
      2
  """
  @spec default(nil, old) :: old when old: var
  @spec default(new, _ :: any()) :: new when new: var
  def default(nil, old), do: old
  def default(new, _), do: new

  @doc """
  Asserts that an OK tuple is `{:ok, value}` and returns the value.
  Raises the error if the tuple is `{:error, error}`.

  ## Examples

      iex> DocSpec.Util.ok!({:ok, 1})
      1
      iex> DocSpec.Util.ok!(:ok)
      :ok

      iex> DocSpec.Util.ok!({:error, "error"})
      ** (RuntimeError) error

      iex> DocSpec.Util.ok!({:error, %File.Error{path: "file", reason: :enoent}})
      ** (File.Error) could not  \"file\": no such file or directory

      iex> DocSpec.Util.ok!({:error, %{foo: "bar"}})
      ** (RuntimeError) %{foo: "bar"}
  """
  @spec ok!(:ok) :: :ok
  @spec ok!({:ok, value}) :: value when value: var
  @spec ok!({:error, any()}) :: no_return()
  def ok!(:ok), do: :ok
  def ok!({:ok, value}), do: value
  def ok!({:error, error}) when is_exception(error), do: raise(error)
  def ok!({:error, error}) when is_binary(error), do: raise(error)
  def ok!({:error, error}), do: raise(inspect(error))

  @doc """
  Tests an OK-tuple, returning the value if the tuple is `{:ok, value}` or returning whatever is
  returned by calling the given function with the error if the tuple is `{:error, error}`.

  ## Examples

        iex> DocSpec.Util.ok_else({:ok, 1}, 2)
        1
        iex> DocSpec.Util.ok_else({:error, "error"}, fn error -> String.upcase(error) end)
        "ERROR"
        iex> DocSpec.Util.ok_else(:ok, :abc)
        :ok
  """
  @spec ok_else(:ok, any()) :: :ok
  @spec ok_else({:ok, value}, any()) :: value when value: var
  @spec ok_else({:error, error}, (error -> return)) :: return when error: var, return: var
  def ok_else(:ok, _), do: :ok
  def ok_else({:ok, value}, _), do: value
  def ok_else({:error, error}, func) when is_function(func, 1), do: func.(error)

  @doc """
  Returns true if the two lists have the same values, regardless of order.

  ## Examples

      iex> DocSpec.Util.same_values([], [])
      true
      iex> DocSpec.Util.same_values([1, 2, 3], [1, 2, 3])
      true
      iex> DocSpec.Util.same_values([1, 2, 3], [3, 2, 1])
      true
      iex> DocSpec.Util.same_values([1, 2, 3], [1, 2, 4])
      false
      iex> DocSpec.Util.same_values([1, 2, 3], [1, 2, 3, 4])
      false
  """
  @spec same_values(a :: [term()], b :: [term()]) :: boolean()
  def same_values(a, b) when a == b, do: true
  def same_values(a, b), do: MapSet.new(a) == MapSet.new(b)

  @doc """
  Encodes a map, list, keyword list, tuple or any other term into a format that can be encoded with Jason
  without raising an error. Also handles some special cases to make the output more readable.

  ## Examples

      iex> DocSpec.Util.encode(%{a: 1, b: 2})
      %{a: 1, b: 2}
      iex> DocSpec.Util.encode([1, 2, 3])
      [1, 2, 3]
      iex> DocSpec.Util.encode([a: 1, b: 2])
      %{a: 1, b: 2}
      iex> DocSpec.Util.encode({:parameterized, {Ecto.Enum, %{data: [1, 2, 3]}}})
      [:parameterized, "Ecto.Enum"]
      iex> DocSpec.Util.encode({"error", [type: {"error", "details"}, validation: :inclusion]})
      ["error", %{type: ["error", "details"], validation: :inclusion}]
  """
  @spec encode(term()) :: term()
  def encode({:parameterized, {Ecto.Enum, _}}),
    do: [:parameterized, "Ecto.Enum"]

  def encode({message, details}),
    do: [message, details] |> encode()

  def encode(errors) when errors |> is_map(),
    do: errors |> Map.new(fn {field, error} -> {field, error |> encode()} end)

  def encode(errors) when errors |> is_list() do
    if errors |> Keyword.keyword?() do
      errors |> Map.new(fn {key, value} -> {key, value |> encode()} end)
    else
      errors |> Enum.map(&encode/1)
    end
  end

  def encode(x), do: x
end
