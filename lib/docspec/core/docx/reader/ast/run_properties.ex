defmodule DocSpec.Core.DOCX.Reader.AST.RunProperties do
  @moduledoc """
  This module defines a struct that represents a `w:rPr` (run properties) object in a Word document.

  See http://officeopenxml.com/WPtextFormatting.php for more information on what a `w:rPr` object may contain.
  """

  alias DocSpec.Core.DOCX.Reader
  alias DocSpec.Core.DOCX.Reader.AST.Fonts
  alias DocSpec.Core.DOCX.Reader.AST.RunProperties
  alias DocSpec.Core.DOCX.Reader.Files.Styles

  import DocSpec.Util, only: [default: 2]

  @typedoc """
  A struct representing the run properties of a run of text in a Word document.

  Definition of values:
  - `true`: explicitly active
  - `false`: explicitly inactive
  - `nil`: implicitly inactive
  """
  @type t :: %__MODULE__{
          style_id: String.t() | nil,
          bold: boolean() | nil,
          italic: boolean() | nil,
          underline: boolean() | nil,
          strike: boolean() | nil,
          superscript: boolean() | nil,
          subscript: boolean() | nil,
          code: boolean() | nil,
          fonts: Fonts.t(),
          highlight: RunProperties.Highlight.t() | nil,
          color: RunProperties.Hex.t() | nil,
          shade: RunProperties.Hex.t() | nil
        }

  @fields [
    :style_id,
    :bold,
    :code,
    :italic,
    :strike,
    :underline,
    :superscript,
    :subscript,
    :fonts,
    :highlight,
    :color,
    :shade
  ]
  @enforce_keys @fields
  defstruct @fields

  @spec parse(Saxy.XML.element() | nil, Reader.t()) :: t()

  def parse(nil, _) do
    %RunProperties{
      style_id: nil,
      bold: nil,
      italic: nil,
      underline: nil,
      strike: nil,
      superscript: nil,
      subscript: nil,
      code: nil,
      fonts: Fonts.parse(nil),
      highlight: nil,
      color: nil,
      shade: nil
    }
  end

  def parse({"w:rPr", _, children}, docx = %Reader{}) do
    [r_style, bold, italic, underline, strike, fonts, vert_align, highlight, color, shade] =
      children
      |> SimpleForm.Element.find_many_by_name([
        "w:rStyle",
        "w:b",
        "w:i",
        "w:u",
        "w:strike",
        "w:rFonts",
        "w:vertAlign",
        "w:highlight",
        "w:color",
        "w:shd"
      ])

    style_id = r_style |> SimpleForm.Attrs.get_value("w:val")
    style = docx.styles |> Styles.get(style_id)

    %RunProperties{
      style_id: style_id,
      bold: parse_bool(bold),
      italic: parse_bool(italic),
      underline: parse_bool(underline),
      strike: parse_bool(strike),
      superscript: parse_vert_align(vert_align) == :superscript,
      subscript: parse_vert_align(vert_align) == :subscript,
      code: if(is_nil(style), do: nil, else: style.type == :code),
      fonts: Fonts.parse(fonts),
      highlight:
        highlight |> SimpleForm.Attrs.get_value("w:val") |> RunProperties.Highlight.parse(),
      color: color |> SimpleForm.Attrs.get_value("w:val") |> RunProperties.Hex.parse(),
      shade:
        if SimpleForm.Attrs.get_value(shade, "w:val") in ["clear", "nil", nil] do
          shade |> SimpleForm.Attrs.get_value("w:fill") |> RunProperties.Hex.parse()
        else
          shade |> SimpleForm.Attrs.get_value("w:fill") |> RunProperties.Hex.parse()
        end
    }
  end

  @spec parse_vert_align(nil) :: nil
  def parse_vert_align(nil), do: nil

  @spec parse_vert_align(Saxy.XML.element()) :: :subscript | :superscript | nil
  def parse_vert_align({"w:vertAlign", attrs, _}) do
    case attrs |> SimpleForm.Attrs.get_value("w:val") do
      "subscript" -> :subscript
      "superscript" -> :superscript
      _ -> nil
    end
  end

  @spec parse_bool(nil) :: nil
  def parse_bool(nil), do: nil

  @spec parse_bool(Saxy.XML.element()) :: boolean()
  def parse_bool({_, attrs, _}) do
    case attrs |> SimpleForm.Attrs.get_value("w:val") do
      # For example: <w:b w:val="false"/>
      "false" -> false
      # For example: <w:b w:val="0"/>
      "0" -> false
      # For example: <w:u w:val="none"/>
      "none" -> false
      # For example: <w:b/>, <w:b w:val="1"/>, <w:b w:val="true"/>
      _ -> true
    end
  end

  @spec merge(new :: nil, old :: nil) :: nil
  @spec merge(new :: nil, old :: t()) :: old :: t()
  @spec merge(new :: t(), old :: nil) :: new :: t()
  @spec merge(new :: t(), old :: t()) :: t()
  def merge(nil, nil), do: nil
  def merge(nil, old), do: old
  def merge(new, nil), do: new

  def merge(new = %RunProperties{}, old = %RunProperties{}) do
    %RunProperties{
      style_id: new.style_id |> default(old.style_id),
      bold: new.bold |> default(old.bold),
      code: new.code |> default(old.code),
      italic: new.italic |> default(old.italic),
      strike: new.strike |> default(old.strike),
      underline: new.underline |> default(old.underline),
      subscript: new.subscript |> default(old.subscript),
      superscript: new.superscript |> default(old.superscript),
      fonts: Fonts.merge(new.fonts, old.fonts),
      highlight: new.highlight |> default(old.highlight),
      color: new.color |> default(old.color),
      shade: new.shade |> default(old.shade)
    }
  end

  alias DocSpec.Spec.{HexColor, Styles}

  @doc """
  Converts a `RunProperties` struct to a `DocSpec.Spec.Styles` struct.

  ## Examples

      iex> alias DocSpec.Core.DOCX.Reader.AST.RunProperties
      iex> alias DocSpec.Spec.{HexColor, Styles}
      iex> props = %RunProperties{
      ...>   style_id: "test",
      ...>   bold: true,
      ...>   italic: false,
      ...>   underline: false,
      ...>   strike: false,
      ...>   superscript: false,
      ...>   subscript: false,
      ...>   code: false,
      ...>   fonts: nil,
      ...>   highlight: :yellow,
      ...>   color: "#8C594F",
      ...>   shade: "#005AFF"
      ...> }
      iex> RunProperties.to_styles(props)
      %Styles{bold: true, text_color: %HexColor{hex: "#8C594F"}, highlight_color: %HexColor{hex: "#ffff00"}}
      iex> RunProperties.to_styles(%RunProperties{props | italic: true, underline: true})
      %Styles{bold: true, italic: true, underline: true, text_color: %HexColor{hex: "#8C594F"}, highlight_color: %HexColor{hex: "#ffff00"}}
      iex> RunProperties.to_styles(%RunProperties{props | highlight: nil})
      %Styles{bold: true, text_color: %HexColor{hex: "#8C594F"}, highlight_color: %HexColor{hex: "#005AFF"}}
      iex> RunProperties.to_styles(%RunProperties{props | highlight: nil, color: nil, shade: nil})
      %Styles{bold: true}
  """
  @spec to_styles(RunProperties.t()) :: Styles.t()
  def to_styles(props = %RunProperties{}) do
    highlight_hex = RunProperties.Highlight.to_hex(props.highlight) || props.shade

    %Styles{
      bold: props.bold == true,
      italic: props.italic == true,
      underline: props.underline == true,
      strikethrough: props.strike == true,
      superscript: props.superscript == true,
      subscript: props.subscript == true,
      code: props.code == true,
      text_color: if(props.color, do: %HexColor{hex: props.color}),
      highlight_color: if(highlight_hex, do: %HexColor{hex: highlight_hex})
    }
  end
end
