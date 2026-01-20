defmodule DocSpec.Core.HTML.Writer do
  @moduledoc """
  Writer for HTML, converting from Spec to HTML.
  """

  # credo:disable-for-next-line Credo.Check.Readability.AliasOrder
  alias NeoSaxy.SimpleForm
  alias DocSpec.Core.HTML.Writer.{Head, SimpleForm, State}
  alias DocSpec.Core.Util.Asset, as: AssetUtil
  alias DocSpec.Spec.Preformatted

  alias DocSpec.Spec.{
    AssetSource,
    BlockQuotation,
    Content,
    DefinitionDetails,
    DefinitionList,
    DefinitionTerm,
    Document,
    DocumentMeta,
    DocumentSpecification,
    Footnote,
    FootnoteReference,
    Heading,
    Image,
    Link,
    ListItem,
    OrderedList,
    Paragraph,
    Styles,
    Table,
    TableCell,
    TableHeader,
    TableRow,
    Text,
    UnorderedList,
    UriSource
  }

  # BCP 47 language tag for undetermined language
  @fallback_lang "und"

  # This defines functions to be generated in the for-loops below.
  #
  # This is a tuple in format:
  #   1. Struct from Spec.
  #   2. HTML Tag that tis element will be wrapped in
  #   3. Attributes to pass to &html_attributes/3
  @element_mappings [
    {BlockQuotation, "blockquote", [:cite]},
    {DefinitionDetails, "dd", []},
    {DefinitionList, "dl", []},
    {DefinitionTerm, "dt", []},
    {Document, "body", []},
    {Footnote, "li", []},
    {FootnoteReference, "a", []},
    {Heading, "p", [:level]},
    {Image, "img", []},
    {Link, "a", [:uri, :purpose]},
    {ListItem, "li", []},
    {Paragraph, "p", []},
    {Preformatted, "code", []},
    {OrderedList, "ol", [:style_type, :start, :reversed]},
    {Table, "table", []},
    {TableCell, "td", [:rowspan, :colspan]},
    {TableHeader, "th", [:rowspan, :colspan, :abbreviation, :scope]},
    {TableRow, "tr", []},
    {UnorderedList, "ul", [:style_type]}
  ]

  @style_mappings [
    bold: "strong",
    italic: "em",
    underline: "u",
    strikethrough: "s",
    code: "code",
    superscript: "sup",
    subscript: "sub",
    mark: "mark"
  ]

  @type html_tag_or_text() :: Floki.html_tag() | Floki.html_text()
  @type acc() :: {[html_tag_or_text()], State.t()}

  @type opt() :: {:pretty, boolean()} | {:fn_asset_to_uri, (DocSpec.Spec.Asset.t() -> String.t())}

  @doc """
  Convert resources into Floki's Simple Form. Either pass a DocumentSpecification, or pass a List of resources.

  ## Examples

    iex> alias DocSpec.Spec.{Heading, Paragraph, Text, Styles, Document, DocumentSpecification}
    iex> italic = %Styles{italic: true}
    iex> bold = %Styles{bold: true}
    iex> resources = [
    ...>   %Heading{
    ...>     level: 1,
    ...>     children: [
    ...>       %Text{text: "Hello "},
    ...>       %Text{text: "World", styles: italic}
    ...>     ]
    ...>   },
    ...>   %Paragraph{
    ...>     children: [
    ...>       %Text{text: "Followed by a "},
    ...>       %Text{text: "paragraph", styles: bold},
    ...>       %Text{text: "."}
    ...>     ]
    ...>   }
    ...> ]
    iex> DocSpec.Core.HTML.Writer.convert_to_simple_form(resources)
    [{"h1", [], ["Hello ", {"em", [], ["World"]}]}, {"p", [], ["Followed by a ", {"strong", [], ["paragraph"]}, "."]}]
    iex> spec = %DocumentSpecification{document: %Document{children: resources}}
    iex> DocSpec.Core.HTML.Writer.convert_to_simple_form(spec)
    {"html", [{"lang", "und"}], [
      {"head", [], [
        {"title", [], ["Document"]},
        {"style", [], [
          "section.footnotes { border-top: 1px solid; }",
          ".lst-square { list-style-type: square; }",
          ".lst-circle { list-style-type: circle; }"
        ]}
      ]},
      {"body", [], [
        {"h1", [], ["Hello ", {"em", [], ["World"]}]},
        {"p", [], ["Followed by a ", {"strong", [], ["paragraph"]}, "."]}
      ]}
    ]}
  """
  @spec convert_to_simple_form(content :: DocumentSpecification.t(), opts :: [opt()]) ::
          Floki.html_tag()
  @spec convert_to_simple_form(content :: Document.t(), opts :: [opt()]) :: Floki.html_tag()
  @spec convert_to_simple_form(content :: [struct()], opts :: [opt()]) :: [
          Floki.html_node()
        ]
  def convert_to_simple_form(content, opts \\ [])

  def convert_to_simple_form(%DocumentSpecification{document: document}, opts),
    do: convert_to_simple_form(document, opts)

  def convert_to_simple_form(content, opts) do
    fn_asset_to_uri = Keyword.get(opts, :fn_asset_to_uri, &AssetUtil.to_base64/1)

    content
    |> add_start_state(fn_asset_to_uri)
    |> convert_resources()
    |> elem(0)
    |> SimpleForm.reverse()
  end

  @doc """
  Convert resources into raw HTML. Either pass a DocumentSpecification, or pass a List of resources.

  ## Examples

    iex> alias DocSpec.Spec.{Heading, Paragraph, Text, Styles}
    iex> italic = %Styles{italic: true}
    iex> bold = %Styles{bold: true}
    iex> [
    ...>   %Heading{
    ...>     level: 1,
    ...>     children: [
    ...>       %Text{text: "Hello "},
    ...>       %Text{text: "World", styles: italic}
    ...>     ]
    ...>   },
    ...>   %Paragraph{
    ...>     children: [
    ...>       %Text{text: "Followed by a "},
    ...>       %Text{text: "paragraph", styles: bold},
    ...>       %Text{text: "."}
    ...>     ]
    ...>   }
    ...> ]
    ...> |> DocSpec.Core.HTML.Writer.convert()
    "<h1>Hello <em>World</em></h1><p>Followed by a <strong>paragraph</strong>.</p>"
  """
  @spec convert(content :: DocumentSpecification.t() | Document.t() | [struct()], [opt()]) ::
          String.t()
  def convert(content, opts \\ []),
    do:
      content
      |> convert_to_simple_form(opts)
      |> Floki.raw_html(opts |> Enum.filter(&match?({:pretty, _}, &1)))
      |> maybe_add_doctype(
        match?(%DocumentSpecification{}, content) or match?(%Document{}, content)
      )

  @spec add_start_state(content, fn_asset_to_uri :: (DocSpec.Spec.Asset.t() -> String.t())) ::
          {content, acc()}
        when content: term()
  defp add_start_state(content, fn_asset_to_uri),
    do: {content, {[], to_state(content, fn_asset_to_uri)}}

  @spec to_state(content :: term(), fn_asset_to_uri :: (DocSpec.Spec.Asset.t() -> String.t())) ::
          State.t()
  defp to_state(%Document{assets: assets, footnotes: footnotes}, fn_asset_to_uri),
    do: %State{
      assets: assets,
      existing_footnote_ids: footnotes |> Enum.map(fn %Footnote{id: id} -> id end),
      fn_asset_to_uri: fn_asset_to_uri
    }

  defp to_state(_, fn_asset_to_uri),
    do: %State{fn_asset_to_uri: fn_asset_to_uri}

  # Floki's Doctype support sucks, therefore doing string manipulation
  @spec maybe_add_doctype(html :: String.t(), boolean()) :: String.t()
  defp maybe_add_doctype(html, add?) when add? and is_binary(html),
    do: "<!DOCTYPE html>\n" <> html

  defp maybe_add_doctype(html, _add?) when is_binary(html),
    do: html

  @spec convert_resources({[struct()], acc()}) :: {[Floki.html_tag()], acc()}
  defp convert_resources({resources, acc}) when is_list(resources) do
    Enum.reduce(
      resources,
      {[], acc},
      fn child, {html_elements, acc} ->
        {html_element, acc} = convert_resources({child, acc})

        if is_nil(html_element) do
          {html_elements, acc}
        else
          {[html_element | html_elements], acc}
        end
      end
    )
  end

  @spec convert_resources({struct(), acc()}) :: {Floki.html_tag() | nil, acc()}
  # The tag for Headings is determined by it's level
  defp convert_resources({resource = %Heading{level: level, children: children}, acc})
       when level <= 6 do
    ("h" <> Integer.to_string(level))
    |> SimpleForm.tag()
    |> tuple(acc)
    |> put_children(children)
    |> postprocess_element(resource)
  end

  for {struct_module, html_tag, attributes} <- @element_mappings do
    if Map.has_key?(struct_module.__struct__(), :children) do
      defp convert_resources({resource = %unquote(struct_module){children: children}, acc}),
        do:
          unquote(html_tag)
          |> SimpleForm.tag()
          |> SimpleForm.put_attributes(
            unquote(html_tag)
            |> html_attributes(resource, unquote(attributes), acc)
          )
          |> tuple(acc)
          |> put_children(children)
          |> postprocess_element(resource)
    else
      defp convert_resources({resource = %unquote(struct_module){}, acc}),
        do:
          unquote(html_tag)
          |> SimpleForm.tag()
          |> SimpleForm.put_attributes(
            unquote(html_tag)
            |> html_attributes(resource, unquote(attributes), acc)
          )
          |> tuple(acc)
          |> postprocess_element(resource)
    end
  end

  defp convert_resources({resource = %Text{text: text, styles: styles}, acc}),
    do: text |> wrap_styling(styles) |> tuple(acc) |> postprocess_element(resource)

  @spec postprocess_element(
          {Floki.html_tag(), acc()},
          struct()
        ) :: {Floki.html_tag() | Floki.html_text() | nil, acc()}

  defp postprocess_element({node = {"body", _, _}, {elements, state}}, doc = %Document{}),
    do:
      "html"
      |> SimpleForm.tag([{"lang", extract_language(doc)}])
      |> SimpleForm.put_children([
        doc
        |> footnote_tags(state)
        |> Enum.reduce(
          node,
          fn child, body -> body |> SimpleForm.prepend_child(child) end
        ),
        doc |> Head.element()
      ])
      |> tuple({elements, state})

  defp postprocess_element({{"a", attrs, []}, {elements, state}}, %FootnoteReference{
         resource_id: resource_id
       }) do
    {num, state} = State.upsert_footnote_id(state, resource_id)

    if is_nil(num) do
      # Footnote referenced to does not exist.
      {nil, {elements, state}}
    else
      "sup"
      |> SimpleForm.tag()
      |> SimpleForm.prepend_child(
        "a"
        |> SimpleForm.tag(attrs)
        |> SimpleForm.prepend_child(num |> Integer.to_string())
      )
      |> tuple({elements, state})
    end
  end

  defp postprocess_element({node = {"a", _, _}, acc}, %Link{
         id: id,
         text: text,
         styles: styles
       }),
       do: {node, acc} |> put_children([%Text{id: id, text: text, styles: styles}])

  defp postprocess_element({node = {"img", _, _}, acc}, %Image{caption: caption})
       when caption != [] do
    {html_caption, acc} = {SimpleForm.tag("figcaption"), acc} |> put_children(caption)

    "figure"
    |> SimpleForm.tag()
    |> SimpleForm.prepend_child(node)
    |> SimpleForm.prepend_child(html_caption)
    |> tuple(acc)
  end

  defp postprocess_element({{"table", attrs, children}, acc}, %Table{caption: caption})
       when caption != [] do
    if Enum.empty?(children) do
      {SimpleForm.tag("div"), acc} |> put_children(caption)
    else
      {html_caption, acc} = {SimpleForm.tag("caption"), acc} |> put_children(caption)
      {"table", attrs, [{"tbody", [], children}, html_caption]} |> tuple(acc)
    end
  end

  defp postprocess_element({{"table", attrs, children}, acc}, _table = %Table{}) do
    if Enum.empty?(children) do
      nil |> tuple(acc)
    else
      {"table", attrs, [{"tbody", [], children}]} |> tuple(acc)
    end
  end

  defp postprocess_element({node = {"blockquote", _, _}, acc}, %BlockQuotation{caption: caption})
       when caption != [] do
    {html_footer, acc} = {SimpleForm.tag("footer"), acc} |> put_children(caption)

    node
    |> SimpleForm.prepend_child(html_footer)
    |> tuple(acc)
  end

  defp postprocess_element({node = {"code", _, _}, acc}, %Preformatted{caption: []}),
    do: "pre" |> SimpleForm.tag([], [node]) |> tuple(acc)

  defp postprocess_element({node = {"code", _, _}, acc}, %Preformatted{caption: caption}) do
    {html_caption, acc} = {SimpleForm.tag("figcaption"), acc} |> put_children(caption)

    "figure"
    |> SimpleForm.tag()
    |> SimpleForm.prepend_child(SimpleForm.tag("pre", [], [node]))
    |> SimpleForm.prepend_child(html_caption)
    |> tuple(acc)
  end

  defp postprocess_element({node, acc}, _), do: {node, acc}

  @spec put_children({Floki.html_tag(), acc()}, [struct()]) ::
          {Floki.html_tag(), acc()}

  # Unwrap paragraph if consists of a single Paragraph.
  defp put_children({node = {name, _attrs, _children}, acc}, [%Paragraph{children: children}])
       when name in ["td", "th", "li", "caption", "figcaption", "footer"],
       do: {node, acc} |> put_children(children)

  defp put_children({node, acc}, children) do
    {children_elements, acc} = children |> tuple(acc) |> convert_resources()

    node
    |> SimpleForm.put_children(children_elements)
    |> tuple(acc)
  end

  @spec image_attributes_alt(alt_text :: String.t() | nil, decorative? :: boolean()) :: [
          Floki.html_attribute()
        ]

  defp image_attributes_alt(alt_text, decorative?)

  defp image_attributes_alt(_alt_text, true),
    # @see: https://www.w3.org/WAI/tutorials/images/decorative/
    do: [{"alt", ""}]

  defp image_attributes_alt(alt_text, false) do
    if Content.discernible_text?(alt_text) do
      [{"alt", alt_text}]
    else
      # The alt attribute is officially mandatory; it's meant to always be specified.
      # See: https://developer.mozilla.org/en-US/docs/Web/API/HTMLImageElement/alt
      [{"alt", ""}]
    end
  end

  @spec html_attributes(
          tag_name :: binary(),
          resource :: struct(),
          keys :: [atom()],
          acc :: acc()
        ) :: [Floki.html_attribute()]

  @spec html_attributes(
          tag_name :: binary(),
          key :: atom(),
          value :: any(),
          acc :: acc()
        ) :: [Floki.html_attribute()]

  defp html_attributes("img", resource = %Image{}, _keys, acc),
    do:
      html_attributes("img", :source, resource.source, acc) ++
        image_attributes_alt(resource.alternative_text, resource.decorative)

  defp html_attributes("img", :source, %AssetSource{asset_id: asset_id}, {_, state = %State{}}) do
    asset = state |> State.find_asset(asset_id)

    if is_nil(asset) do
      []
    else
      [{"src", State.asset_to_uri(state, asset)}]
    end
  end

  defp html_attributes("img", :source, %UriSource{uri: uri}, _acc),
    do: [{"src", uri}]

  defp html_attributes("li", %Footnote{id: id}, _keys, _acc),
    do: [{"id", "fn-" <> id}]

  defp html_attributes("a", %FootnoteReference{resource_id: resource_id}, _keys, _acc),
    do: [{"href", "#fn-" <> resource_id}, {"role", "doc-noteref"}]

  defp html_attributes(tag_name, resource, keys, acc)
       when is_struct(resource) and is_list(keys),
       do:
         keys
         |> Enum.flat_map(fn key ->
           tag_name |> html_attributes(key, resource |> Map.get(key), acc)
         end)

  for html_tag <- ["ol", "ul"] do
    # Don't output if equal to default. Save the planet by saving bytes.
    defp html_attributes(unquote(html_tag), :start, 1, _acc), do: []

    defp html_attributes(unquote(html_tag), :start, n, _acc),
      do: [{"start", n |> Integer.to_string()}]
  end

  # Don't output if equal to default. Save the planet by saving bytes.
  defp html_attributes("ol", :reversed, false, _acc), do: []
  defp html_attributes("ol", :reversed, true, _acc), do: [{"reversed", ""}]

  # Don't output if equal to default. Save the planet by saving bytes.
  defp html_attributes("ul", :style_type, "disc", _acc), do: []
  defp html_attributes("ul", :style_type, "circle", _acc), do: [{"class", "lst-circle"}]
  defp html_attributes("ul", :style_type, "square", _acc), do: [{"class", "lst-square"}]

  # Don't output if equal to default. Save the planet by saving bytes.
  defp html_attributes("ol", :style_type, "decimal", _acc), do: []

  # TODO: Recommended against using attribute, but is not deprecated. Research if we should use CSS.
  defp html_attributes("ol", :style_type, "lower-alpha", _acc), do: [{"type", "a"}]
  defp html_attributes("ol", :style_type, "upper-alpha", _acc), do: [{"type", "A"}]
  defp html_attributes("ol", :style_type, "lower-roman", _acc), do: [{"type", "i"}]
  defp html_attributes("ol", :style_type, "upper-roman", _acc), do: [{"type", "I"}]

  defp html_attributes("p", :level, n, _acc),
    do: [{"role", "heading"}, {"aria-level", n |> Integer.to_string()}]

  for html_tag <- ["td", "th"] do
    # @see https://developer.mozilla.org/en-US/docs/Web/HTML/Element/td#rowspan
    # @see https://developer.mozilla.org/en-US/docs/Web/HTML/Element/th#rowspan
    # @see https://developer.mozilla.org/en-US/docs/Web/API/HTMLTableCellElement/rowSpan

    # Don't output if equal to default or invalid. Save the planet by saving bytes.
    defp html_attributes(unquote(html_tag), :rowspan, n, _acc)
         when n <= 1,
         do: []

    # Values higher than 65534 are clipped to 65534.
    defp html_attributes(unquote(html_tag), :rowspan, n, acc)
         when n > 65_534,
         do: html_attributes(unquote(html_tag), :rowspan, 65_534, acc)

    # If its value is set to 0, the header cell will extends to the end of the table grouping
    # section (<thead>, <tbody>, <tfoot>, even if implicitly defined), that the <th> or <td> belongs to.
    defp html_attributes(unquote(html_tag), :rowspan, n, _acc) when n < 0,
      do: []

    defp html_attributes(unquote(html_tag), :rowspan, n, _acc),
      do: [{"rowspan", n |> Integer.to_string()}]

    # @see https://developer.mozilla.org/en-US/docs/Web/HTML/Element/td#colspan
    # @see https://developer.mozilla.org/en-US/docs/Web/HTML/Element/th#colspan
    # @see https://developer.mozilla.org/en-US/docs/Web/API/HTMLTableCellElement/colSpan

    # User agents dismiss values higher than 1000 as incorrect, setting to the default value (1).
    # Don't output if equal to default or invalid. Save the planet by saving bytes.
    defp html_attributes(unquote(html_tag), :colspan, n, _acc) when n <= 1 or n > 1000,
      do: []

    defp html_attributes(unquote(html_tag), :colspan, n, _acc),
      do: [{"colspan", n |> Integer.to_string()}]
  end

  defp html_attributes("th", :scope, :column, _acc), do: [{"scope", "col"}]
  defp html_attributes("th", :scope, :row, _acc), do: [{"scope", "row"}]

  for {html_tag, html_attribute, key} <- [
        {"th", "abbr", :abbreviation},
        {"blockquote", "cite", :cite},
        {"a", "aria-label", :purpose}
      ] do
    defp html_attributes(unquote(html_tag), unquote(key), nil, _acc), do: []

    defp html_attributes(unquote(html_tag), unquote(key), value, _acc) do
      if Content.discernible_text?(value) do
        [{unquote(html_attribute), value}]
      else
        []
      end
    end
  end

  # Set referrerpolicy for privacy and security reasons.
  # Keep target to default '_self' for accessibility reasons. Avoid confusion that
  # may be caused by the appearance of new windows that were not requested by the user.
  # Suddenly opening new windows can disorient users or be missed completely by some.
  #
  # @see https://developer.mozilla.org/en-US/docs/Web/HTML/Element/a#referrerpolicy
  # @see https://developer.mozilla.org/en-US/docs/Web/HTML/Element/a#target
  # @see https://www.w3.org/TR/WCAG20-TECHS/H83.html
  defp html_attributes("a", :uri, uri, _acc),
    do: [{"href", uri}, {"referrerpolicy", "same-origin"}]

  defp html_attributes(_, _, _, _), do: []

  @spec footnote_tags(Document.t(), State.t()) :: [Floki.html_tag()]

  defp footnote_tags(_doc, %State{ordered_footnote_ids: ordered_ids})
       when map_size(ordered_ids) === 0,
       do: []

  defp footnote_tags(
         %Document{footnotes: footnotes},
         state = %State{ordered_footnote_ids: ordered_ids}
       ),
       do:
         "section"
         |> SimpleForm.tag([{"class", "footnotes"}])
         |> SimpleForm.prepend_child(
           "ol"
           |> SimpleForm.tag()
           |> tuple({[], state})
           |> put_children(
             ordered_ids
             |> Enum.sort_by(fn {_id, num} -> num end)
             |> Enum.flat_map(fn {id, _num} -> footnotes |> find_footnotes(id) end)
           )
           |> elem(0)
         )
         |> List.wrap()

  @spec find_footnotes(footnotes :: [Footnote.t()], id :: String.t()) :: [Footnote.t()]

  defp find_footnotes(footnotes, id),
    do: footnotes |> Enum.filter(fn %Footnote{id: footnote_id} -> footnote_id == id end)

  @spec wrap_styling(html_tag_or_text(), Styles.t() | nil) :: html_tag_or_text()
  defp wrap_styling(node, nil), do: node

  defp wrap_styling(node, styles = %Styles{}) do
    @style_mappings
    |> Enum.reduce(node, fn {style_key, html_tag}, acc ->
      if Map.get(styles, style_key, false) do
        {html_tag, [], [acc]}
      else
        acc
      end
    end)
  end

  @spec extract_language(Document.t()) :: String.t()
  defp extract_language(%Document{metadata: %DocumentMeta{language: language}})
       when is_binary(language) and language != "",
       do: language

  defp extract_language(_document),
    do: @fallback_lang

  defp tuple(a, b), do: {a, b}
end
