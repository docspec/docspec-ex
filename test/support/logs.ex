defmodule DocSpec.Test.Logs do
  @moduledoc """
  This module helps with capturing log output in tests.
  """

  @type log() ::
          {time :: String.t(), metadata :: metadata(), level :: String.t(), message :: String.t()}
  @type metadata() :: %{String.t() => String.t()}

  @doc """
  For use with &ExUnit.CaptureLog.capture_log/2.

  ## Examples

      iex> DocSpec.Test.Logs.opts()
      [colors: [enabled: false], format: "$time $metadata[$level] $message\\n", metadata: :all]
      iex> DocSpec.Test.Logs.opts(format: "$message")
      [colors: [enabled: false], metadata: :all, format: "$message"]
      iex> DocSpec.Test.Logs.opts(level: :info)
      [colors: [enabled: false], format: "$time $metadata[$level] $message\\n", metadata: :all, level: :info]
  """
  @spec opts(keyword()) :: keyword()
  def opts(opts \\ []) when is_list(opts) do
    [
      colors: [enabled: false],
      format: "$time $metadata[$level] $message\n",
      metadata: :all
    ]
    |> Keyword.merge(opts)
  end

  @doc """
  For parsing multiple lines of log.

  ## Examples

      iex> "23:09:04.123 line=114 file=lib/ex_unit/capture_log.ex [info] hello this is a test\\n" <>
      ...> "22:08:03.193 line=124 file=lib/ex_unit/capture_log.ex [error] Lorem, ipsum, dolor sit.\\n"
      ...> |> DocSpec.Test.Logs.parse!()
      [
        {
          "23:09:04.123",
          %{"line" => "114", "file" => "lib/ex_unit/capture_log.ex"},
          "info",
          "hello this is a test"
        },
        {
          "22:08:03.193",
          %{"line" => "124", "file" => "lib/ex_unit/capture_log.ex"},
          "error",
          "Lorem, ipsum, dolor sit."
        }
      ]
      iex> DocSpec.Test.Logs.parse!("Not following format.")
      ** (RuntimeError) Log does not follow format: "Not following format."
  """
  def parse!(log) when is_binary(log) do
    log
    |> String.split("\n", trim: true)
    |> Enum.map(&parse_line!/1)
  end

  @doc """
  Parsing a single line of log.

  ## Examples

      iex> "23:09:04.123 line=114 file=lib/ex_unit/capture_log.ex [info] hello this is a test"
      ...> |> DocSpec.Test.Logs.parse_line!()
      {"23:09:04.123", %{"line" => "114", "file" => "lib/ex_unit/capture_log.ex"}, "info", "hello this is a test"}
      iex> DocSpec.Test.Logs.parse_line!("Not following format.")
      ** (RuntimeError) Log does not follow format: "Not following format."
  """
  @spec parse_line!(log :: String.t()) :: log()
  def parse_line!(log) when is_binary(log) do
    regex =
      ~r/^(?<time>\d{2}:\d{2}:\d{2}\.\d{3})\s+(?<metadata>.*?)\s+\[(?<severity>[^\]]+)\]\s+(?<message>.*)$/

    case Regex.named_captures(regex, log) do
      %{"time" => time, "metadata" => metadata, "severity" => severity, "message" => message} ->
        {time, parse_metadata(metadata), severity, message}

      _ ->
        raise "Log does not follow format: #{inspect(log)}"
    end
  end

  @doc """
  Parsing metadata.

  ## Examples

      iex> "23:09:04.123 hello=world service.name=docspec_foo"
      ...> |> DocSpec.Test.Logs.parse_metadata()
      %{"hello" => "world", "service.name" => "docspec_foo"}
  """
  @spec parse_metadata(metadata :: String.t()) :: metadata()
  def parse_metadata(metadata) when is_binary(metadata) do
    metadata
    |> String.split(~r/\s+/, trim: true)
    |> Enum.reduce(%{}, fn kv, acc ->
      case String.split(kv, "=", parts: 2) do
        [key, value] -> Map.put(acc, key, value)
        _ -> acc
      end
    end)
  end
end
