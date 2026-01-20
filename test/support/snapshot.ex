defmodule DocSpec.Test.Snapshot do
  @moduledoc """
  This module provides snapshot testing functionality for ExUnit tests.
  """
  require ExUnit.Assertions

  @doc """
  Asserts that the actual value matches the expected value saved in a snapshot file.
  The actual value is always saved (inspect/2 with pretty: true) to a file named `actual.exs`.

  ## Options

  * `:save_expected` - Save the actual value as the expected value for the snapshot. This overwrites the existing expected value.
  * `:format` - Format the actual value in specific format. Currently supports `:exs`, `:json`, and `:html`.
  """
  @type destination() :: :actual | :expected
  @type filetype() :: :exs | :json | :html
  @type opt() :: {:save_expected, boolean()} | {:format, filetype()}

  @spec assert_snapshot(any(), String.t(), [opt()]) :: boolean()
  def assert_snapshot(actual_value, snapshot_name, opts \\ []) do
    filetype = Keyword.get(opts, :format, :exs)

    save_snapshot(actual_value, snapshot_name, :actual, filetype)

    if Keyword.get(opts, :save_expected, false) do
      save_snapshot(actual_value, snapshot_name, :expected, filetype)
    end

    expected_value = load_snapshot!(snapshot_name, filetype)

    unless expected_value === actual_value do
      raise ExUnit.AssertionError,
        left: expected_value,
        right: actual_value,
        expr: "Snapshot == Received",
        message: snapshot_name |> format_snapshot_does_not_match(filetype)
    end

    true
  end

  @spec save_snapshot(any(), String.t(), destination(), filetype()) :: :ok
  def save_snapshot(actual_value, name, destination, filetype) do
    full_snapshot_path = snapshot_path(name, destination, filetype)

    full_snapshot_path |> Path.dirname() |> File.mkdir_p!()
    full_snapshot_path |> File.write!(format(actual_value, filetype))
  end

  @spec format(any(), :exs) :: String.t()
  @spec format(map(), :json) :: String.t()
  @spec format(String.t(), :html) :: String.t()
  defp format(data, :exs), do: inspect(data, pretty: true, limit: :infinity)
  defp format(data, :json), do: Jason.encode!(data, pretty: true) <> "\n"
  defp format(data, :html), do: data

  @spec load_snapshot!(String.t(), :exs) :: any()
  @spec load_snapshot!(String.t(), :json) :: map()
  @spec load_snapshot!(String.t(), :html) :: String.t()
  def load_snapshot!(name, filetype) do
    case filetype do
      :exs -> load_exs_snapshot!(name)
      :json -> load_json_snapshot!(name)
      :html -> load_html_snapshot!(name)
    end
  rescue
    error in File.Error ->
      if error.reason === :enoent do
        message = format_snapshot_not_found(name, filetype)
        reraise %ExUnit.AssertionError{message: message}, __STACKTRACE__
      else
        reraise error, __STACKTRACE__
      end
  end

  defp load_json_snapshot!(name) do
    name |> snapshot_path(:expected, :json) |> File.read!() |> Jason.decode!()
  end

  defp load_exs_snapshot!(name) do
    {result, _binding} =
      name
      |> snapshot_path(:expected, :exs)
      |> File.read!()
      |> Code.eval_string()

    result
  end

  defp load_html_snapshot!(name) do
    name |> snapshot_path(:expected, :html) |> File.read!()
  end

  @spec snapshot_path(String.t(), destination(), filetype()) :: String.t()
  def snapshot_path(name, destination, filetype) do
    Path.join(["test", "snapshots", name, snapshot_filename(destination, filetype)])
  end

  @spec snapshot_filename(destination(), filetype()) :: String.t()
  defp snapshot_filename(destination, filetype),
    do: "#{Atom.to_string(destination)}.#{Atom.to_string(filetype)}"

  @spec format_how_to_update_expected(String.t(), filetype()) :: String.t()
  def format_how_to_update_expected(snapshot_name, filetype) do
    """
    If the actual value is correct, save it as the snapshot's expected value by running the following command:

    $ cp '#{snapshot_path(snapshot_name, :actual, filetype)}' '#{snapshot_path(snapshot_name, :expected, filetype)}'

    Or use the `:save_expected` option on `assert_snapshot/3` to overwrite the expected value.
    """
  end

  def format_snapshot_not_found(snapshot_name, filetype) do
    """
    No expected value is saved for snapshot "#{snapshot_name}".

    #{format_how_to_update_expected(snapshot_name, filetype)}
    """
  end

  def format_snapshot_does_not_match(snapshot_name, filetype) do
    """
    Snapshot test on #{snapshot_name} failed: actual value does not match the expected value. Please see the difference below.

    If the actual value is correct, save it as the snapshot's expected value by running the following command:

    $ cp '#{snapshot_path(snapshot_name, :actual, filetype)}' '#{snapshot_path(snapshot_name, :expected, filetype)}'

    Or use the `:save_expected` option on `assert_snapshot/3` to overwrite the expected value.
    """
  end
end
