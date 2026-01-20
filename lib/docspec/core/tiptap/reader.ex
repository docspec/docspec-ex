defmodule DocSpec.Core.Tiptap.Reader do
  @moduledoc """
  Reader for convert_elementing Tiptap elements to Spec Resources.
  """

  use TypedStruct

  defmodule State do
    @moduledoc """
    Format of state modified during converting.
    """

    typedstruct enforce: true do
      field :footnotes, [DocSpec.Spec.Footnote.t()], default: []
    end
  end

  defmodule Context do
    @moduledoc """
    Context for conversion that is only relevant to children and not to be passed back.
    """

    typedstruct enforce: true do
      field :strict?, boolean()
    end
  end

  @type opt() :: {:strict, boolean()}
  @type error() :: {:error, term()}

  @type input(resource) :: {resource, state :: State.t(), ctx :: Context.t()}
  @type output(value) :: {:ok, {value, state :: State.t()}} | error()

  @type tiptap_element() :: %{required(:type) => String.t()}

  @spec convert(doc :: tiptap_element(), opts: [opt()]) ::
          {:ok, DocSpec.Spec.DocumentSpecification.t()} | error()
  def convert(doc = %{type: "doc"}, opts \\ []) do
    state = %State{}
    ctx = %Context{strict?: Keyword.get(opts, :strict, false)}

    case convert_element({doc, state, ctx}) do
      {:ok, {[resource = %DocSpec.Spec.Document{}], state = %State{}}} ->
        document = reverse(%{resource | footnotes: state.footnotes})
        {:ok, %DocSpec.Spec.DocumentSpecification{document: document}}
    end
  end

  @conversions [
    {DocSpec.Spec.Document, "doc"},
    {DocSpec.Spec.Paragraph, "paragraph"},
    {DocSpec.Spec.Heading, "heading"},
    {DocSpec.Spec.Table, "table"},
    {DocSpec.Spec.TableRow, "tableRow"},
    {DocSpec.Spec.TableCell, "tableCell"},
    {DocSpec.Spec.TableHeader, "tableHeader"},
    {DocSpec.Spec.DefinitionList, "definitionList"},
    {DocSpec.Spec.DefinitionTerm, "definitionTerm"},
    {DocSpec.Spec.DefinitionDetails, "definitionDetails"},
    {DocSpec.Spec.OrderedList, "orderedList"},
    {DocSpec.Spec.UnorderedList, "bulletList"},
    {DocSpec.Spec.ListItem, "listItem"},
    {DocSpec.Spec.Preformatted, "codeBlock"},
    {DocSpec.Spec.BlockQuotation, "blockquote"}
  ]

  for {module, element_name} <- @conversions do
    @spec convert_element(input(map())) :: output([unquote(module).t()])
    defp convert_element(
           {element = %{type: unquote(element_name)}, state = %State{}, ctx = %Context{}}
         ) do
      with {:ok, {resource = %unquote(module){}, state = %State{}}} <-
             apply_attributes({%unquote(module){}, state, ctx}, element),
           {:ok, {children, state = %State{}}} <-
             convert_children({Map.get(element, :content, []), state, ctx}, &convert_element/1) do
        {:ok, {[%unquote(module){} = %{resource | children: children}], state}}
      end
    end
  end

  @spec convert_element(input(map())) :: output([DocSpec.Spec.FootnoteReference.t()])
  defp convert_element({element = %{type: "footnote"}, state = %State{}, ctx = %Context{}}) do
    with {:ok, {resource = %DocSpec.Spec.Footnote{}, state = %State{}}} <-
           apply_attributes({%DocSpec.Spec.Footnote{}, state, ctx}, element),
         {:ok, {children, state = %State{}}} <-
           convert_children({Map.get(element, :content, []), state, ctx}, &convert_element/1) do
      %DocSpec.Spec.Footnote{} =
        footnote = %{
          resource
          | children: [
              %DocSpec.Spec.Paragraph{
                id: Ecto.UUID.generate(),
                children: children
              }
            ]
        }

      {:ok,
       {[%DocSpec.Spec.FootnoteReference{id: Ecto.UUID.generate(), resource_id: footnote.id}],
        %State{} = %{state | footnotes: [footnote | state.footnotes]}}}
    end
  end

  @spec convert_element(input(map())) :: output([DocSpec.Spec.Image.t()])
  defp convert_element({element = %{type: "image"}, state = %State{}, ctx = %Context{}}) do
    with {:ok, {resource = %DocSpec.Spec.Image{}, state = %State{}}} <-
           apply_attributes({%DocSpec.Spec.Image{}, state, ctx}, element) do
      if resource.source do
        {:ok, {[resource], state}}
      else
        {:ok, {[], state}}
      end
    end
  end

  @spec convert_element(input(map())) :: output([DocSpec.Spec.Text.t()])
  @spec convert_element(input(map())) :: output([DocSpec.Spec.Link.t()])
  defp convert_element({element = %{type: "text"}, state = %State{}, _ctx = %Context{}}) do
    marks = Map.get(element, :marks, [])

    link_mark = Enum.find(marks, &match?(%{type: "link"}, &1))

    meta_attrs =
      marks
      |> Enum.find(%{}, &match?(%{type: "meta"}, &1))
      |> Map.get(:attrs, %{})

    resource =
      if link_mark do
        link_attrs = Map.get(link_mark, :attrs, %{})

        %DocSpec.Spec.Link{
          id: meta_attrs |> Map.get(:id) |> uuid_if_nil(),
          text: Map.get(element, :text, ""),
          uri: Map.get(link_attrs, :href),
          purpose: link_attrs |> Map.get(:purpose) |> empty_string_as_nil(),
          styles: marks_to_styles(marks)
        }
      else
        %DocSpec.Spec.Text{
          id: meta_attrs |> Map.get(:id) |> uuid_if_nil(),
          text: Map.get(element, :text, ""),
          styles: marks_to_styles(marks)
        }
      end

    {:ok, {[resource], state}}
  end

  defp convert_element({_unsupported_resource, state = %State{}, _ctx = %Context{}}),
    do: {:ok, {[], state}}

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

  @attr_conversions [
    {DocSpec.Spec.Document,
     [
       id: {:id, :uuid_if_nil},
       assets: {:assets, :modify_assets}
     ]},
    {DocSpec.Spec.Paragraph,
     [
       id: {:id, :uuid_if_nil}
     ]},
    {DocSpec.Spec.Heading,
     [
       id: {:id, :uuid_if_nil},
       level: {:level, nil}
     ]},
    {DocSpec.Spec.Table,
     [
       id: {:id, :uuid_if_nil}
     ]},
    {DocSpec.Spec.TableRow,
     [
       id: {:id, :uuid_if_nil},
       colspan: {:colspan, nil},
       rowspan: {:rowspan, nil}
     ]},
    {DocSpec.Spec.TableCell,
     [
       id: {:id, :uuid_if_nil},
       colspan: {:colspan, nil},
       rowspan: {:rowspan, nil}
     ]},
    {DocSpec.Spec.TableHeader,
     [
       id: {:id, :uuid_if_nil}
     ]},
    {DocSpec.Spec.DefinitionList,
     [
       id: {:id, :uuid_if_nil}
     ]},
    {DocSpec.Spec.DefinitionTerm,
     [
       id: {:id, :uuid_if_nil}
     ]},
    {DocSpec.Spec.DefinitionDetails,
     [
       id: {:id, :uuid_if_nil}
     ]},
    {DocSpec.Spec.OrderedList,
     [
       id: {:id, :uuid_if_nil},
       start: {:start, nil}
     ]},
    {DocSpec.Spec.UnorderedList,
     [
       id: {:id, :uuid_if_nil},
       style_type: {:style_type, nil}
     ]},
    {DocSpec.Spec.ListItem,
     [
       id: {:id, :uuid_if_nil}
     ]},
    {DocSpec.Spec.Preformatted,
     [
       id: {:id, :uuid_if_nil}
     ]},
    {DocSpec.Spec.BlockQuotation,
     [
       id: {:id, :uuid_if_nil}
     ]},
    {DocSpec.Spec.Image,
     [
       id: {:id, :uuid_if_nil},
       decorative: {:decorative, nil},
       alternative_text: {:alt, nil},
       source: {:assetId, :normalize_asset_source}
     ]},
    {DocSpec.Spec.Footnote,
     [
       id: {:id, :uuid_if_nil}
     ]}
  ]

  for {module, mapping} <- @attr_conversions do
    attrs_var = Macro.var(:attrs, nil)
    resource_var = Macro.var(:resource, nil)

    pipeline_ast =
      Enum.reduce(mapping, quote(do: unquote(resource_var)), fn {field, {tiptap_attr, modifier}},
                                                                acc ->
        base_val_ast =
          quote do
            Map.get(unquote(attrs_var), unquote(tiptap_attr), nil)
          end

        val_ast =
          case modifier do
            nil ->
              base_val_ast

            fun_name when is_atom(fun_name) ->
              quote do
                unquote(fun_name)(unquote(base_val_ast))
              end
          end

        quote do
          val = unquote(val_ast)

          if is_nil(val) do
            unquote(acc)
          else
            struct(unquote(acc), %{unquote(field) => val})
          end
        end
      end)

    @spec apply_attributes(input(%unquote(module){}), map()) :: output(%unquote(module){})

    defp apply_attributes(
           {resource = %unquote(module){}, state = %State{}, _ctx = %Context{}},
           tiptap_element = %{}
         ) do
      attrs = Map.get(tiptap_element, :attrs, %{})
      {:ok, {unquote(pipeline_ast), state}}
    end
  end

  @spec marks_to_styles([term()]) :: DocSpec.Spec.Styles.t()
  defp marks_to_styles(marks) when is_list(marks) do
    mark_types = marks |> Enum.map(&Map.get(&1, :type)) |> MapSet.new()

    %DocSpec.Spec.Styles{
      bold: "bold" in mark_types,
      italic: "italic" in mark_types,
      underline: "underline" in mark_types,
      strikethrough: "strike" in mark_types,
      superscript: "superscript" in mark_types,
      subscript: "subscript" in mark_types,
      code: "code" in mark_types
    }
  end

  @spec uuid_if_nil(nil) :: String.t()
  defp uuid_if_nil(nil),
    do: Ecto.UUID.generate()

  @spec uuid_if_nil(value) :: value when value: term()
  defp uuid_if_nil(value),
    do: value

  @spec normalize_asset_source(value :: String.t()) :: DocSpec.Spec.AssetSource.t()
  defp normalize_asset_source(value) when is_binary(value),
    do: %DocSpec.Spec.AssetSource{asset_id: value}

  @spec normalize_asset_source(value) :: value when value: term()
  defp normalize_asset_source(value),
    do: value

  @spec empty_string_as_nil(value :: String.t()) :: String.t() | nil
  @spec empty_string_as_nil(value) :: value when value: term()
  defp empty_string_as_nil(""),
    do: nil

  defp empty_string_as_nil(value),
    do: value

  @spec modify_assets(assets :: term()) :: [DocSpec.Spec.Asset.t()] | nil
  defp modify_assets(assets) when is_map(assets) do
    Enum.reduce(
      assets,
      [],
      fn {id, data_uri}, acc ->
        asset = DocSpec.Core.Util.Asset.from_data_uri(Atom.to_string(id), data_uri)
        [asset | acc]
      end
    )
  end

  defp modify_assets(_assets),
    do: nil

  @spec reverse(content) :: content when content: term()
  defp reverse(content) when is_list(content),
    do: content |> Enum.map(&reverse/1) |> Enum.reverse()

  defp reverse(resource = %{children: children}) when is_list(children),
    do: Map.put(resource, :children, reverse(children))

  defp reverse(other),
    do: other
end
