defmodule DocSpec.Core.DOCX.Reader.Convert do
  @moduledoc """
  Converts a `Docx` struct into a DocSpec Spec document, raising any errors that occur during the conversion.

  This module implements a recursive conversion of the XML structure of a Word document into a DocSpec Spec document.
  Its implementation in DocSpec was first written by Stephan Meijer and later refactored by Bart van Oort.

  Huge thanks to [Pandoc](https://github.com/jgm/pandoc) for inspiration and guidance on how to convert Word documents to a structured format.

  ## Supported Features

  - [x] Title elements (becomes heading)
  - [x] Headings
  - [x] Text Paragraphs
  - [x] Definition lists, details and terms
  - [x] Preformatted blocks, also known as "Source Code"
  - [x] Text in Wingdings, Webdings and Symbol fonts is converted to UTF-8 equivalents
  - [-] Hyperlinks (missing support for `w:r` with `w:instrText` child that contains a hyperlink field code)
  - [-] Tables (missing support for rowspan, table captions)
  - [-] Ordered and Unordered lists (Windings as list characters are not implemented).
  - [-] Images (only in `w:drawing`, media is not yet exported to assets and missing support for captions)
  - [ ] Captions
  - [ ] LineBreak
  - [ ] Alternate content
  """

  import DocSpec.Core.DOCX.Reader.AST.Fonts, only: [is_special_font: 1]
  import DocSpec.Core.DOCX.Reader.{State, Util.Helpers}

  alias DocSpec.Core.DOCX.Reader
  alias DocSpec.Core.DOCX.Reader.{Convert, PostProcess, State}

  alias DocSpec.Core.DOCX.Reader.AST.{
    Fonts,
    NumberingProperties,
    ParagraphProperties,
    RunProperties
  }

  alias DocSpec.Core.DOCX.Reader.Files.{CoreProperties, Numberings, Relationship, Styles}

  alias DocSpec.Spec.{
    AssetSource,
    Document,
    DocumentSpecification,
    Image,
    Link,
    Table,
    TableCell,
    TableRow,
    Text,
    UriSource
  }

  @spec convert(Reader.t()) :: DocumentSpecification.t()
  def convert(docx = %Reader{core_properties: core_properties, document: document}) do
    {children, state} = document.root |> convert({[], %State{}}, docx)

    doc =
      %Document{
        id: new_id(),
        metadata: core_properties |> CoreProperties.convert()
      }
      |> add_children(children)
      |> PostProcess.process(state, docx)

    %DocumentSpecification{document: doc}
  end

  # -----------------------------------------------------------------------------------------------

  @type conversion() :: {resources :: [struct()], state :: State.t()}
  @spec convert(
          elements :: Saxy.XML.element() | [Saxy.XML.element()],
          accumulator :: conversion(),
          docx :: Reader.t()
        ) :: conversion()

  def convert([], acc), do: acc

  def convert([head | rest], {res, start_state = %State{}}, docx) do
    {res, head_state} = head |> convert({res, start_state}, docx)
    {res, rest_state} = rest |> convert({res, head_state |> keep(start_state, :styling)}, docx)
    {res, rest_state |> keep(start_state, :styling)}
  end

  # -----------------------------------------------------------------------------------------------
  # Paragraphs

  def convert({"w:p", _attrs, []}, acc, _docx), do: acc

  def convert(
        {"w:p", _attrs, xml_children},
        {resources, current_state = %State{}},
        docx = %Reader{}
      ) do
    paragraph_properties =
      xml_children
      |> SimpleForm.Element.find_by_name("w:pPr")
      |> ParagraphProperties.parse()

    style = docx.styles |> Styles.get(paragraph_properties.style_id)
    num_def = docx.numberings |> Numberings.get(paragraph_properties)

    {children, new_state} = xml_children |> convert({[], current_state}, docx)

    children
    |> Convert.Paragraph.convert(
      {
        resources,
        new_state
        |> track_list_counter(paragraph_properties.num_properties)
      },
      docx,
      style,
      paragraph_properties,
      num_def
    )
  end

  # -----------------------------------------------------------------------------------------------
  # Tables

  def convert({"w:tbl", _, children}, {resources, current_state = %State{}}, docx) do
    {table_children, new_state} = children |> convert({[], current_state}, docx)

    resource = %Table{} |> add_children(table_children)
    {resources |> add(resource), new_state}
  end

  def convert({"w:tr", _, children}, {resources, current_state = %State{}}, docx) do
    {row_children, new_state} = children |> convert({[], current_state}, docx)

    resource = %TableRow{} |> add_children(row_children)
    {resources |> add(resource), new_state}
  end

  def convert({"w:tc", _, children}, {resources, current_state = %State{}}, docx) do
    colspan =
      children
      |> SimpleForm.Element.find_by_name("w:tcPr", nil, recursive: false)
      |> SimpleForm.Element.children()
      |> SimpleForm.Element.find_by_name("w:gridSpan", nil, recursive: false)
      |> SimpleForm.Attrs.get_value("w:val", "1")
      |> String.to_integer()

    {cell_children, new_state} = children |> convert({[], current_state}, docx)

    resource = %TableCell{colspan: colspan} |> add_children(cell_children)
    {resources |> add(resource), new_state}
  end

  # -----------------------------------------------------------------------------------------------
  # Images and drawings
  #
  # TODO: detect and convert image captions

  def convert({"w:drawing", _, children}, {resources, current_state}, docx = %Reader{}) do
    rel_id =
      children
      |> SimpleForm.Element.find_by_name("a:blip", nil, recursive: true)
      |> SimpleForm.Attrs.get_value("r:embed")

    alt =
      children
      |> SimpleForm.Element.find_by_name("wp:docPr", nil, recursive: true)
      |> SimpleForm.Attrs.get_value("descr")

    src = docx.document.rels |> Relationship.get_target(rel_id, :image)

    case src do
      nil ->
        {resources, current_state}

      "" ->
        {resources, current_state}

      _ ->
        {source, current_state} =
          if DocSpec.Util.StringFormat.uri?(src) do
            {%UriSource{uri: src}, current_state}
          else
            {id, current_state} = current_state |> State.upsert_asset(src)
            {%AssetSource{asset_id: id}, current_state}
          end

        resource = %Image{source: source, alternative_text: alt}
        {resources |> add(resource), current_state}
    end
  end

  # -----------------------------------------------------------------------------------------------
  # Text and Hyperlinks
  #
  # TODO: handle `w:r` with `w:instrText` child that contains a hyperlink field code,
  #       e.g. <w:instrText>HYPERLINK "https://www.deviantart.com/printinredink/art/Firefly-swirling-colors-with-bubbles-and-droplets-970346778"</w:instrText>
  #       Such a run is preceded by a `w:r` with `<w:fldChar w:fldCharType="begin" />`,
  #       followed by runs with text (the hyperlink text),
  #       followed by a `w:r` with `<w:fldChar w:fldCharType="end" />`.
  # Currently we do correctly extract the text, but we don't make it a hyperlink.

  def convert(
        {"w:hyperlink", attrs, xml_children},
        {resources, current_state = %State{}},
        docx = %Reader{}
      ) do
    rel_id = attrs |> SimpleForm.Attrs.get_value("r:id")

    raw_target =
      docx.document.rels
      |> Relationship.get_target(rel_id, :hyperlink)

    hyperlink_target = if(raw_target == "", do: nil, else: raw_target)

    {children, new_state} =
      xml_children
      |> convert({[], current_state |> set(:hyperlink_target, hyperlink_target)}, docx)

    {resources |> add_all(children), new_state |> set(:hyperlink_target, nil)}
  end

  def convert({"w:r", _, children}, {resources, current_state = %State{}}, docx = %Reader{}) do
    run_styling =
      children
      |> SimpleForm.Element.find_by_name("w:rPr")
      |> RunProperties.parse(docx)
      |> RunProperties.merge(current_state.styling)

    children |> convert({resources, current_state |> set(:styling, run_styling)}, docx)
  end

  def convert({"w:br", _, _}, {resources, current_state = %State{}}, _docx) do
    styles = current_state.styling |> RunProperties.to_styles()
    new_line = %Text{text: "\n", styles: styles}
    {resources |> add(new_line), current_state}
  end

  def convert({"w:t", _, children}, {resources, current_state = %State{}}, _docx) do
    current_font = current_state.styling.fonts.ascii
    styles = current_state.styling |> RunProperties.to_styles()

    text =
      if is_special_font(current_font) do
        children |> SimpleForm.Element.text() |> Fonts.font(current_font).to_utf8()
      else
        children |> SimpleForm.Element.text()
      end

    resource =
      if is_nil(current_state.hyperlink_target) do
        %Text{
          text: text |> HtmlEntities.decode(),
          styles: styles
        }
      else
        %Link{
          text: text |> HtmlEntities.decode(),
          styles: styles,
          uri: current_state.hyperlink_target
        }
      end

    case text do
      # Skip empty text elements. Note: we should only skip empty strings, whitespace is valid content here.
      "" -> {resources, current_state}
      _ -> {resources |> add(resource), current_state}
    end
  end

  def convert({"w:sym", attrs, _}, acc, docx) do
    [font, char] = attrs |> SimpleForm.Attrs.get_many_value(["w:font", "w:char"])
    text = char |> String.to_integer(16) |> Fonts.font(font).to_utf8()

    case text do
      nil -> acc
      # To avoid duplicating logic, we'll pretend this symbol was wrapped in a `w:t`.
      _ -> {"w:t", [], [text]} |> convert(acc, docx)
    end
  end

  # -----------------------------------------------------------------------------------------------
  # Alternate Content

  # This skips converting alternateContent (WordArt, textboxes, etc.), as we don't do anything with them yet.
  # TODO Implement proper logic for alternateContent that handles paragraphs inside paragraphs
  def convert({"mc:AlternateContent", _, _}, acc, _), do: acc

  # -----------------------------------------------------------------------------------------------
  # Default behaviour

  # Default behaviour for all other elements is to recurse into their children
  def convert({_, _, children}, {resources, current_state}, docx) do
    children |> convert({resources, current_state}, docx)
  end

  # other content is ignored
  def convert(_, acc, _), do: acc

  @spec track_list_counter(
          state :: State.t(),
          numbering_properties :: NumberingProperties.t() | nil
        ) :: State.t()
  defp track_list_counter(state = %State{numbering_id: num_id}, %NumberingProperties{
         num_id: num_id,
         ilvl: 0
       }),
       do: state |> set(:last_root_list_count, state.last_root_list_count + 1)

  defp track_list_counter(state = %State{}, %NumberingProperties{ilvl: 0}),
    do: state |> set(:last_root_list_count, 0)

  defp track_list_counter(state = %State{}, _),
    do: state
end
