defmodule DocSpec.Core.DOCX.Reader.AST.Fonts.SpecialFont do
  @moduledoc """
  This module provides a basis for implementing UTF-8 conversions of special fonts like Symbol, Wingdings and Webdings.

  ## Usage

  Create a module for your font, `use` this module and provide a `symbols` map
  mapping codepoints in your font to UTF-8 codepoints.

  For example:

      defmodule DocSpec.Core.DOCX.Reader.AST.Fonts.Symbol do
        use DocSpec.Core.DOCX.Reader.AST.Fonts.SpecialFont,
          symbols: %{
            0x20 => 0xA0,
            0x21 => 0x21,
            # etc ...
          }
      end

  ## Acknowledgements

  Many thanks to Pandoc author [John MacFarlane (jgm)](https://github.com/jgm) for helping us map the Wingdings and Webdings fonts
  and helping us figure out how to perform the conversion to UTF-8.

  @see https://github.com/jgm/pandoc/issues/9220
  """

  # coveralls-ignore-start This code is part of a macro and cannot covered by tests.
  defmacro __using__(opts) do
    symbols_opt = opts |> Keyword.get(:symbols)
    {symbols, _} = Code.eval_quoted(symbols_opt, [], __CALLER__)
    symbols |> validate_symbols()
    # coveralls-ignore-stop

    quote location: :keep do
      @symbols unquote(symbols_opt)

      alias DocSpec.Core.DOCX.Reader.AST.Fonts.FontBehaviour
      @behaviour FontBehaviour

      @doc """
      Converts a string to UTF-8 using the special font's codepoints.
      Alternatively, converts a single codepoint to UTF-8 using the special font's codepoints.
      Any unrecognized codepoints are converted to nil and removed from the string.
      """
      @impl FontBehaviour
      def to_utf8(string) when is_binary(string) do
        string
        |> String.to_charlist()
        |> Enum.map(&to_utf8/1)
        |> Enum.reject(&is_nil/1)
        |> List.to_string()
      end

      @impl FontBehaviour
      def to_utf8(codepoint) when is_integer(codepoint) and codepoint > 0xF000,
        do: to_utf8(codepoint - 0xF000)

      @impl FontBehaviour
      def to_utf8(codepoint) when is_integer(codepoint) do
        case @symbols |> Map.get(codepoint) do
          nil -> nil
          utf8_codepoint -> <<utf8_codepoint::utf8>>
        end
      end
    end
  end

  # coveralls-ignore-start validate_symbols is only used inside a macro and cannot covered by tests.

  # Compile-time validation of the symbols argument, which must be a map of integers to integers.
  defp validate_symbols(symbols) when is_nil(symbols) do
    raise """
    You must provide a map of symbols to codepoints when using the SpecialFont module.
    """
  end

  defp validate_symbols(symbols) when is_map(symbols) do
    symbols
    |> Enum.each(fn {key, value} ->
      unless is_integer(key) do
        raise """
        All keys in the symbols map must be integers, but the type of key #{inspect(key)} is #{Useful.typeof(key)}.
        """
      end

      unless is_integer(value) do
        raise """
        All values in the symbols map must be integers, but the type of the value for #{inspect(key)} is #{Useful.typeof(value)}.
        """
      end
    end)
  end

  defp validate_symbols(symbols) do
    raise """
    The symbols argument must be a map, but the type of symbols is #{Useful.typeof(symbols)}.
    """
  end

  # coveralls-ignore-stop
end
