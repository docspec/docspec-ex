defmodule DocSpec.Core.Tiptap.Writer do
  @moduledoc """
  This writer converts DocSpec Spec objects to Tiptap Elements.
  """

  use TypedStruct

  alias DocSpec.Core.Util.Asset, as: AssetUtil

  alias DocSpec.Spec.{
    Asset,
    AssetSource,
    BlockQuotation,
    DefinitionDetails,
    DefinitionList,
    DefinitionTerm,
    Document,
    DocumentSpecification,
    Heading,
    Image,
    Link,
    ListItem,
    OrderedList,
    Paragraph,
    Preformatted,
    Styles,
    Table,
    TableCell,
    TableHeader,
    TableRow,
    Text,
    UnorderedList,
    UriSource
  }

  defmodule State do
    @moduledoc """
    Format of state modified during converting.
    """

    typedstruct enforce: true do
      field :assets, [DocSpec.Spec.Asset.t()]
    end
  end

  defmodule Context do
    @moduledoc """
    Context for conversion that is only relevant to children and not to be passed back.
    """

    typedstruct enforce: true do
      field :strict?, boolean()
      field :parent, module(), default: nil
    end
  end

  @type tiptap_attribute_map() :: %{atom() => term()}
  @type tiptap_mark() :: map()
  @type tiptap_element() :: %{atom() => term()}

  @type opt() :: {:strict, boolean()}
  @type error() :: {:error, {:unsupported_resource, module()}}

  @type input(resource) :: {resource, state :: State.t(), ctx :: Context.t()}
  @type output(value) :: {:ok, {value, state :: State.t()}} | error()

  @doc """
  Converts DocSpec Spec DocumentSpecification to Tiptap document
  """
  @spec convert(spec :: DocumentSpecification.t(), opts :: [opt()]) ::
          {:ok, tiptap_element()} | error()
  def convert(%DocumentSpecification{document: doc = %Document{}}, opts \\ []) do
    state = %State{assets: doc.assets}
    ctx = %Context{strict?: Keyword.get(opts, :strict, false), parent: Document}

    case convert_element({doc, state, ctx}) do
      {:ok, {[element], _state = %State{}}} ->
        {:ok, reverse(element)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @resource_conversions [
    {Document, "doc"},
    {BlockQuotation, "blockquote"},
    {Paragraph, "paragraph"},
    {Table, "table"},
    {Heading, "heading"},
    {Preformatted, "codeBlock"},
    {TableRow, "tableRow"},
    {OrderedList, "orderedList"},
    {UnorderedList, "bulletList"},
    {ListItem, "listItem"},
    {TableHeader, "tableHeader"},
    {TableCell, "tableCell"},
    {DefinitionList, "definitionList"},
    {DefinitionTerm, "definitionTerm"},
    {DefinitionDetails, "definitionDetails"}
  ]

  @spec convert_element(input(term())) :: output([tiptap_element()])

  for {module, element_name} <- @resource_conversions do
    defp convert_element({resource = %unquote(module){}, state = %State{}, ctx = %Context{}}) do
      with {:ok, {{attrs, content}, state = %State{}}} <-
             convert_attributes_and_children({resource, state, ctx}) do
        {:ok, {[%{type: unquote(element_name), attrs: attrs, content: content}], state}}
      end
    end
  end

  defp convert_element({resource = %mod{}, state = %State{}, ctx = %Context{}})
       when mod in [Text, Link] do
    with {:ok, {marks, state = %State{}}} <- convert_marks({resource, state, ctx}) do
      {:ok, {[%{type: "text", text: resource.text, marks: marks}], state}}
    end
  end

  defp convert_element({resource = %Image{}, state = %State{}, ctx = %Context{parent: Document}}),
    do:
      {
        %Paragraph{id: Ecto.UUID.generate(), children: [resource]},
        state,
        ctx
      }
      |> convert_element()

  defp convert_element({resource = %Image{}, state = %State{}, ctx = %Context{}}) do
    with {:ok, {attrs, state = %State{}}} <-
           convert_attributes({resource, state, ctx}) do
      {:ok, {[%{type: "image", attrs: attrs}], state}}
    end
  end

  defp convert_element({%mod{}, _state = %State{}, _ctx = %Context{strict?: true}}),
    do: {:error, {:unsupported_resource, mod}}

  defp convert_element({_unsupported_resource, state = %State{}, _ctx = %Context{}}),
    do: {:ok, {[], state}}

  @spec convert_attributes_and_children(input(map())) ::
          output({tiptap_attribute_map(), [tiptap_element()]})
  defp convert_attributes_and_children(
         {resource = %mod{children: children}, state = %State{}, ctx = %Context{}}
       ) do
    with {:ok, {attrs, state = %State{}}} <- convert_attributes({resource, state, ctx}),
         {:ok, {content, state = %State{}}} <-
           convert_children(
             {children, state, %Context{} = %{ctx | parent: mod}},
             &convert_element/1
           ) do
      {:ok, {{attrs, content}, state}}
    end
  end

  @spec convert_children(input([child]), convert_fn :: (input(child) -> output([result]))) ::
          output([result])
        when child: var, result: var
  defp convert_children({children, state = %State{}, ctx = %Context{}}, convert_fn),
    do:
      Enum.reduce(
        children,
        {:ok, {[], state}},
        fn
          child, {:ok, {contents, state}} ->
            with {:ok, {content, state}} <- convert_fn.({child, state, ctx}) do
              {:ok, {content ++ contents, state}}
            end

          _, {:error, reason} ->
            {:error, reason}
        end
      )

  @spec convert_attributes(input(map())) :: output(tiptap_attribute_map())
  defp convert_attributes({resource = %Document{}, state = %State{}, ctx = %Context{}}) do
    with {:ok, {assets = %{}, state = %State{}}} <-
           convert_doc_assets({resource.assets, state, ctx}) do
      {:ok, {%{assets: assets, id: resource.id}, state}}
    end
  end

  defp convert_attributes({resource = %Heading{}, state = %State{}, _ctx = %Context{}}),
    do: {:ok, {%{level: resource.level, id: resource.id}, state}}

  defp convert_attributes({resource = %OrderedList{}, state = %State{}, _ctx = %Context{}}),
    do: {:ok, {%{start: resource.start, id: resource.id}, state}}

  defp convert_attributes({resource = %Image{}, state = %State{}, _ctx = %Context{}}),
    do:
      {:ok,
       {%{
          alt: resource.alternative_text,
          decorative: resource.decorative,
          id: resource.id,
          assetId: normalize_asset_source(resource.source)
        }, state}}

  defp convert_attributes({resource = %mod{}, state = %State{}, _ctx = %Context{}})
       when mod in [TableHeader, TableCell],
       do:
         {:ok, {%{colspan: resource.colspan, rowspan: resource.rowspan, id: resource.id}, state}}

  defp convert_attributes({%{id: id}, state = %State{}, _ctx = %Context{}}) when is_binary(id),
    do: {:ok, {%{id: id}, state}}

  @spec convert_doc_assets(input([Asset.t()])) :: output(%{String.t() => String.t()})
  defp convert_doc_assets({assets, state = %State{}, _ctx = %Context{}}) when is_list(assets) do
    converted_assets =
      assets
      |> Enum.reduce(
        %{},
        fn asset = %Asset{}, converted_assets = %{} ->
          Map.put(converted_assets, asset.id, AssetUtil.to_base64(asset))
        end
      )

    {:ok, {converted_assets, state}}
  end

  @spec convert_marks(input(Text.t())) :: output([tiptap_mark()])
  @spec convert_marks(input(Link.t())) :: output([tiptap_mark()])
  defp convert_marks({resource = %mod{}, state = %State{}, ctx = %Context{}})
       when mod in [Text, Link] do
    with {:ok, {marks, state = %State{}}} <- styles_to_marks({resource.styles, state, ctx}) do
      base_mark = %{type: "meta", attrs: %{id: resource.id}}

      marks =
        case resource do
          %Text{} ->
            [base_mark | marks]

          %Link{uri: href, purpose: purpose} ->
            link_mark = %{type: "link", attrs: %{href: href, purpose: purpose}}
            [base_mark, link_mark] ++ marks
        end

      {:ok, {marks, state}}
    end
  end

  @spec styles_to_marks(input(Styles.t() | nil)) :: output([tiptap_mark()])
  defp styles_to_marks({nil, state = %State{}, _ctx = %Context{}}),
    do: {:ok, {[], state}}

  defp styles_to_marks({styles = %Styles{}, state = %State{}, _ctx = %Context{}}) do
    marks =
      [
        {:strikethrough, "strike"},
        {:code, "code"},
        {:bold, "bold"},
        {:italic, "italic"},
        {:underline, "underline"},
        {:subscript, "subscript"},
        {:superscript, "superscript"}
      ]
      |> Enum.filter(fn {key, _} -> Map.get(styles, key, false) end)
      |> Enum.map(fn {_, tiptap_type} -> %{type: tiptap_type} end)

    {:ok, {marks, state}}
  end

  @spec normalize_asset_source(AssetSource.t() | UriSource.t() | String.t() | nil) ::
          String.t() | nil
  defp normalize_asset_source(%AssetSource{asset_id: asset_id}), do: asset_id
  defp normalize_asset_source(%UriSource{uri: uri}), do: uri

  defp normalize_asset_source(source) when is_binary(source),
    do: source |> String.replace_prefix("#", "")

  defp normalize_asset_source(source), do: source

  @spec reverse(content) :: content when content: term()
  defp reverse(content) when is_list(content),
    do: content |> Enum.map(&reverse/1) |> Enum.reverse()

  defp reverse(resource = %{content: content}) when is_list(content),
    do: Map.put(resource, :content, reverse(content))

  defp reverse(other),
    do: other
end
