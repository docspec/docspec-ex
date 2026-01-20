defmodule DocSpec.Spec.Content do
  @moduledoc """
  Helper functions for interpreting the content of DocSpec Spec objects.
  """

  alias DocSpec.Spec.{Link, Text}

  @doc """
  Returns true if the given text is discernible, i.e. consists of anything else
  than whitespace or invisible characters.

  If the given text is a DocSpec.Spec object, this function will recursively
  check whether any of its children contain discernible text.

  ## Examples

      iex> alias DocSpec.Spec.{Content, Paragraph, Text}
      iex> Content.discernible_text?(
      ...>   %Paragraph{id: "1", children: [
      ...>     %Text{id: "2", text: "This is"},
      ...>     %Text{id: "3", text: " "},
      ...>     %Text{id: "4", text: "an example."},
      ...>   ]}
      ...> )
      true
      iex> Content.discernible_text?("")
      false
      iex> Content.discernible_text?(%Paragraph{id: "1", children: [%Text{id: "2", text: "    "}]})
      false
  """
  @spec discernible_text?(map() | String.t() | nil) :: boolean()
  def discernible_text?(text) when is_binary(text) do
    # \s matches standard whitespace characters.
    # \b matches a backspace character.
    # \x{0085} matches Unicode character U+0085 (Next Line).
    # See also https://en.wikipedia.org/wiki/Whitespace_character#Unicode
    String.replace(
      text,
      ~r/[\s\b\x{0085}\x{00A0}\x{1680}\x{180E}\x{2000}\x{2001}\x{2002}\x{2003}\x{2004}\x{2005}\x{2006}\x{2007}\x{2008}\x{2009}\x{200A}\x{200B}\x{200C}\x{200D}\x{2028}\x{2029}\x{202F}\x{205F}\x{2060}\x{3000}\x{FEFF}]/u,
      ""
    ) != ""
  end

  def discernible_text?(%{text: text}), do: discernible_text?(text)
  def discernible_text?(%{children: children}), do: Enum.any?(children, &discernible_text?/1)
  def discernible_text?(_), do: false

  @doc """
  Returns all the text elements in a series of DocSpec Spec objects,
  concatenated into a single series of texts.

  ## Examples

      iex> alias DocSpec.Spec.{Content, Paragraph, Text}
      iex> Content.text(
      ...>   %Paragraph{id: "1", children: [
      ...>     %Text{id: "2", text: "This is"},
      ...>     %Text{id: "3", text: " "},
      ...>     %Text{id: "4", text: "an example."},
      ...>   ]}
      ...> )
      [%Text{id: "2", text: "This is"}, %Text{id: "3", text: " "}, %Text{id: "4", text: "an example."}]

      iex> alias DocSpec.Spec.{Content, Paragraph, Text}
      iex> Content.text([
      ...>   %Paragraph{id: "1", children: [
      ...>     %Text{id: "2", text: "This is"},
      ...>     %Text{id: "3", text: " "},
      ...>     %Text{id: "4", text: "an example."},
      ...>   ]},
      ...>   %Paragraph{id: "5", children: [
      ...>     %Text{id: "6", text: "And this is"},
      ...>     %Text{id: "7", text: " "},
      ...>     %Text{id: "8", text: "another example."},
      ...>   ]}
      ...> ])
      [%Text{id: "2", text: "This is"}, %Text{id: "3", text: " "}, %Text{id: "4", text: "an example."}, %Text{id: "6", text: "And this is"}, %Text{id: "7", text: " "}, %Text{id: "8", text: "another example."}]

      iex> alias DocSpec.Spec.{Content, Text}
      iex> Content.text(%Text{id: "1", text: "Just a single text object."})
      [%Text{id: "1", text: "Just a single text object."}]
  """
  @spec text(map() | [map()]) :: [Text.t()]
  def text(text = %Text{}) do
    [text]
  end

  def text(%Link{id: id, text: link_text, styles: styles}) do
    [%Text{id: id, text: link_text, styles: styles}]
  end

  def text(%{children: children}) do
    text(children)
  end

  def text(resources) when is_list(resources) do
    resources |> Enum.flat_map(&text/1)
  end

  # Skip non-text inline content (Image, FootnoteReference, Math)
  def text(_), do: []
end
