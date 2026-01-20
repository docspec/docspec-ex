defmodule DocSpec.Core.DOCX.Reader.AST.Fonts do
  @moduledoc """
  This module defines a struct that represents a `w:rFonts` object in a Word document.
  """
  import DocSpec.Util, only: [default: 2]

  alias DocSpec.Core.DOCX.Reader.AST.Fonts

  @type t :: %__MODULE__{
          ascii: String.t() | nil,
          complex_script: String.t() | nil,
          east_asia: String.t() | nil,
          high_ansii: String.t() | nil
        }

  @fields [:ascii, :complex_script, :east_asia, :high_ansii]
  @enforce_keys @fields
  defstruct @fields

  def parse(nil),
    do: %Fonts{ascii: nil, complex_script: nil, east_asia: nil, high_ansii: nil}

  def parse({"w:rFonts", attrs, _}) do
    [ascii, complex_script, high_ansii, east_asia] =
      attrs |> SimpleForm.Attrs.get_many_value(["w:ascii", "w:cs", "w:hAnsi", "w:eastAsia"])

    %Fonts{
      ascii: ascii,
      complex_script: complex_script,
      high_ansii: high_ansii,
      east_asia: east_asia
    }
  end

  def merge(new, old) do
    %Fonts{
      ascii: new.ascii |> default(old.ascii),
      complex_script: new.complex_script |> default(old.complex_script),
      east_asia: new.east_asia |> default(old.east_asia),
      high_ansii: new.high_ansii |> default(old.high_ansii)
    }
  end

  @typedoc """
  This type defines special fonts that won't render properly on the web and will need conversion to UTF-8.
  """
  @type special_font() :: :wingdings | :wingdings2 | :wingdings3 | :webdings | :symbol

  @doc """
  Returns true for font types or font names that are special fonts, i.e. they won't render properly on the
  web and will need conversion to UTF-8.

  Can also be used as a guard clause.

  ## Examples

      iex> import DocSpec.Core.DOCX.Reader.AST.Fonts, only: [is_special_font: 1]
      iex>
      iex> is_special_font(:wingdings)
      true
      iex> is_special_font(:wingdings2)
      true
      iex> is_special_font(:wingdings3)
      true
      iex> is_special_font(:webdings)
      true
      iex> is_special_font(:symbol)
      true
      iex> is_special_font("Wingdings")
      true
      iex> is_special_font("Wingdings 2")
      true
      iex> is_special_font("Wingdings 3")
      true
      iex> is_special_font("Webdings")
      true
      iex> is_special_font("Symbol")
      true
      iex> is_special_font(:utf8)
      false
      iex> is_special_font("UTF8")
      false
  """
  defguard is_special_font(font)
           when font in [:wingdings, :wingdings2, :wingdings3, :webdings, :symbol] or
                  font in ["Wingdings", "Wingdings 2", "Wingdings 3", "Webdings", "Symbol"]

  @doc """
  Given a special font type or special font name, returns a module that implements `DocSpec.Core.DOCX.Reader.AST.Fonts.FontBehaviour`
  for converting characters in that font to UTF-8.
  """
  @spec font(special_font() | String.t()) ::
          Fonts.Wingdings
          | Fonts.Wingdings2
          | Fonts.Wingdings3
          | Fonts.Webdings
          | Fonts.Symbol
          | Fonts.UTF8
  def font(:wingdings), do: Fonts.Wingdings
  def font(:wingdings2), do: Fonts.Wingdings2
  def font(:wingdings3), do: Fonts.Wingdings3
  def font(:webdings), do: Fonts.Webdings
  def font(:symbol), do: Fonts.Symbol
  def font("Wingdings"), do: Fonts.Wingdings
  def font("Wingdings 2"), do: Fonts.Wingdings2
  def font("Wingdings 3"), do: Fonts.Wingdings3
  def font("Webdings"), do: Fonts.Webdings
  def font("Symbol"), do: Fonts.Symbol
  def font(_), do: Fonts.UTF8
end
