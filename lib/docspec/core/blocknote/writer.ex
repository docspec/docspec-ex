defmodule DocSpec.Core.BlockNote.Writer do
  @moduledoc """
  Writer for BlockNote structure.
  """

  use TypedStruct

  alias DocSpec.Core.BlockNote.Writer.Color
  alias DocSpec.Core.Util.Asset, as: AssetUtil
  alias DocSpec.Util.Color.RGB

  alias DocSpec.Spec.{
    Asset,
    AssetSource,
    BlockQuotation,
    Content,
    DefinitionDetails,
    DefinitionList,
    DefinitionTerm,
    Document,
    DocumentSpecification,
    FootnoteReference,
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

    alias DocSpec.Core.BlockNote.Spec.Document, as: BlockNoteDocument

    typedstruct enforce: true do
      field :assets, [DocSpec.Spec.Asset.t()], default: []
      field :parent_list_type, :bullet | :numbered | nil, default: nil
      field :parent_list_start, number() | nil, default: nil
      field :extracted_blocks, [BlockNoteDocument.content()], default: []
    end
  end

  defmodule Context do
    @moduledoc """
    Context for conversion that is only relevant to children and not to be passed back.
    """

    typedstruct enforce: true do
      field :inline_mode?, boolean(), default: false
      field :strict?, boolean(), default: false
    end
  end

  defmodule UnsupportedResource do
    @moduledoc """
    Exception raised when a resource type is not supported during conversion.
    """

    defexception [:resource]

    @type t() :: %__MODULE__{
            resource: term()
          }

    @impl true
    def message(%__MODULE__{resource: resource}) do
      module_name =
        case resource do
          %mod{} -> inspect(mod)
          other -> inspect(other)
        end

      "Unsupported resource: #{module_name}"
    end
  end

  @type error() :: {:error, UnsupportedResource.t()}
  @type opt() :: {:strict, boolean()}

  @max_heading_level 6

  @spec write(spec :: DocumentSpecification.t(), opts: [opt()]) ::
          {:ok, [DocSpec.Core.BlockNote.Spec.Document.content()]} | error()
  def write(%DocumentSpecification{document: document = %Document{}}, opts \\ []) do
    ctx = %Context{strict?: Keyword.get(opts, :strict, false)}

    with {:ok, {[blocknote_document], _state}} <-
           write_resource({document, %State{assets: document.assets}, %Context{} = ctx}),
         do: {:ok, reverse(blocknote_document.content)}
  end

  @spec write_resource({document :: Document.t(), State.t(), Context.t()}) ::
          {:ok, {[DocSpec.Core.BlockNote.Spec.Document.t()], State.t()}} | error()
  defp write_resource(
         {document = %Document{}, state = %State{}, context = %Context{inline_mode?: false}}
       ) do
    with {:ok, {contents, state}} <-
           write_children({document.children, state, context}, &write_resource/1) do
      {:ok,
       {[
          %DocSpec.Core.BlockNote.Spec.Document{
            id: document.id,
            content: contents
          }
        ], state}}
    end
  end

  defp write_resource({%mod{children: []}, state = %State{}, _context})
       when mod in [Table, UnorderedList, OrderedList],
       do: {:ok, {[], state}} |> add_extracted_blocks()

  @spec write_resource({resource :: Paragraph.t(), State.t(), Context.t()}) ::
          {:ok, {[DocSpec.Core.BlockNote.Spec.Paragraph.t()], State.t()}} | error()
  defp write_resource(
         {resource = %Paragraph{}, state = %State{}, context = %Context{inline_mode?: false}}
       ) do
    with {:ok, {contents, state}} <-
           write_text_children(
             {resource.children, state, %Context{} = %{context | inline_mode?: true}},
             &write_resource/1
           ) do
      {:ok,
       {[
          %DocSpec.Core.BlockNote.Spec.Paragraph{
            id: resource.id,
            content: contents,
            props: set_text_alignment(%{}, resource)
          }
        ], state}}
      |> add_extracted_blocks()
    end
  end

  @spec write_resource({resource :: UnorderedList.t(), State.t(), Context.t()}) ::
          {:ok, {[DocSpec.Core.BlockNote.Spec.BulletListItem.t()], State.t()}} | error()
  defp write_resource(
         {resource = %UnorderedList{}, state = %State{}, context = %Context{inline_mode?: false}}
       ) do
    with {:ok, {children, state}} <-
           write_children(
             {resource.children, %State{state | parent_list_type: :bullet}, context},
             &write_resource/1
           ) do
      {:ok, add_extracted_blocks({children, state})}
    end
  end

  @spec write_resource({resource :: OrderedList.t(), State.t(), Context.t()}) ::
          {:ok, {[DocSpec.Core.BlockNote.Spec.NumberedListItem.t()], State.t()}} | error()
  defp write_resource(
         {resource = %OrderedList{}, state = %State{}, context = %Context{inline_mode?: false}}
       ) do
    with {:ok, {children, state}} <-
           write_children(
             {resource.children,
              %State{state | parent_list_type: :numbered, parent_list_start: resource.start},
              context},
             &write_resource/1
           ) do
      {:ok, add_extracted_blocks({children, state})}
    end
  end

  @spec write_resource({resource :: ListItem.t(), State.t(), Context.t()}) ::
          {:ok,
           {[
              DocSpec.Core.BlockNote.Spec.BulletListItem.t()
              | DocSpec.Core.BlockNote.Spec.NumberedListItem.t()
            ], State.t()}}
          | error()
  defp write_resource(
         {resource = %ListItem{}, state = %State{}, context = %Context{inline_mode?: false}}
       ) do
    texts =
      resource.children
      |> Enum.filter(fn %{type: type} -> type == Paragraph.resource_type() end)
      |> Content.text()

    lists =
      resource.children
      |> Enum.filter(fn %{type: type} ->
        type in [OrderedList.resource_type(), UnorderedList.resource_type()]
      end)

    with {:ok, {bn_texts, state = %State{}}} <-
           write_children({texts, state, context}, &write_resource/1),
         {:ok, {nested_items, state = %State{}}} <-
           write_children({lists, state, context}, &write_resource/1) do
      item =
        if state.parent_list_type == :bullet do
          %DocSpec.Core.BlockNote.Spec.BulletListItem{
            id: resource.id,
            content: bn_texts,
            children: nested_items
          }
        else
          %DocSpec.Core.BlockNote.Spec.NumberedListItem{
            id: resource.id,
            content: bn_texts,
            children: nested_items,
            props:
              if is_nil(state.parent_list_start) do
                %{}
              else
                %{start: state.parent_list_start}
              end
          }
        end

      {:ok, {[item], %State{state | parent_list_start: nil}}}
    end
  end

  @spec write_resource({resource :: Image.t(), State.t(), Context.t()}) ::
          {:ok, {[DocSpec.Core.BlockNote.Spec.Image.t()], State.t()}} | error()
  defp write_resource(
         {resource = %Image{source: %AssetSource{asset_id: asset_id}}, state = %State{},
          _context = %Context{inline_mode?: false}}
       ) do
    asset = Enum.find(state.assets, fn %Asset{id: id} -> id == asset_id end)

    if is_nil(asset) do
      {:ok, {[], state}}
      |> add_extracted_blocks()
    else
      {:ok,
       {[
          %DocSpec.Core.BlockNote.Spec.Image{
            id: resource.id,
            props: %{
              url: AssetUtil.to_base64(asset),
              caption: resource.alternative_text || ""
            }
          }
        ], state}}
      |> add_extracted_blocks()
    end
  end

  defp write_resource({%Image{}, state = %State{}, _context = %Context{inline_mode?: false}}) do
    {:ok, {[], state}}
    |> add_extracted_blocks()
  end

  # Handle inline images with AssetSource - extract to extracted_blocks
  defp write_resource(
         {resource = %Image{source: %AssetSource{asset_id: asset_id}}, state = %State{},
          _context = %Context{inline_mode?: true}}
       ) do
    asset = Enum.find(state.assets, fn %Asset{id: id} -> id == asset_id end)

    if is_nil(asset) do
      {:ok, {[], state}}
    else
      image_block = %DocSpec.Core.BlockNote.Spec.Image{
        id: resource.id,
        props: %{
          url: AssetUtil.to_base64(asset),
          caption: resource.alternative_text || ""
        }
      }

      {:ok, {[], %State{state | extracted_blocks: [image_block | state.extracted_blocks]}}}
    end
  end

  # Handle inline images with UriSource - extract to extracted_blocks
  defp write_resource(
         {resource = %Image{source: %UriSource{uri: uri}}, state = %State{},
          _context = %Context{inline_mode?: true}}
       ) do
    image_block = %DocSpec.Core.BlockNote.Spec.Image{
      id: resource.id,
      props: %{
        url: uri,
        caption: resource.alternative_text || ""
      }
    }

    {:ok, {[], %State{state | extracted_blocks: [image_block | state.extracted_blocks]}}}
  end

  # Handle inline images without asset - skip (no image data available)
  defp write_resource({%Image{}, state = %State{}, _context = %Context{inline_mode?: true}}) do
    {:ok, {[], state}}
  end

  @spec write_resource({resource :: Heading.t(), State.t(), Context.t()}) ::
          {:ok, {[DocSpec.Core.BlockNote.Spec.Heading.t()], State.t()}} | error()
  defp write_resource(
         {resource = %Heading{}, state = %State{}, context = %Context{inline_mode?: false}}
       ) do
    with {:ok, {contents, state}} <-
           write_text_children(
             {resource.children, state, %Context{} = %{context | inline_mode?: true}},
             &write_resource/1
           ) do
      {:ok,
       {[
          %DocSpec.Core.BlockNote.Spec.Heading{
            id: resource.id,
            content: contents,
            props:
              %DocSpec.Core.BlockNote.Spec.Heading.Props{
                level: min(resource.level, @max_heading_level),
                text_alignment: "left"
              }
              |> set_text_alignment(resource)
          }
        ], state}}
      |> add_extracted_blocks()
    end
  end

  @spec write_resource({resource :: Preformatted.t(), State.t(), Context.t()}) ::
          {:ok, {[DocSpec.Core.BlockNote.Spec.CodeBlock.t()], State.t()}} | error()
  defp write_resource(
         {resource = %Preformatted{}, state = %State{}, context = %Context{inline_mode?: false}}
       ) do
    with {:ok, {contents, state}} <-
           write_text_children(
             {resource.children, state, %Context{} = %{context | inline_mode?: true}},
             &write_resource/1
           ) do
      {:ok,
       {[
          %DocSpec.Core.BlockNote.Spec.CodeBlock{
            id: resource.id,
            content: contents,
            props: set_text_alignment(%{}, resource)
          }
        ], state}}
      |> add_extracted_blocks()
    end
  end

  @spec write_resource({resource :: BlockQuotation.t(), State.t(), Context.t()}) ::
          {:ok, {[DocSpec.Core.BlockNote.Spec.Quote.t()], State.t()}} | error()
  defp write_resource(
         {resource = %BlockQuotation{}, state = %State{}, context = %Context{inline_mode?: false}}
       ) do
    with {:ok, {contents, state}} <-
           write_text_children(
             {resource.children, state, %Context{} = %{context | inline_mode?: true}},
             &write_resource/1
           ) do
      {:ok,
       {[
          %DocSpec.Core.BlockNote.Spec.Quote{
            id: resource.id,
            content: contents,
            props: set_text_alignment(%{}, resource)
          }
        ], state}}
      |> add_extracted_blocks()
    end
  end

  @spec write_resource({resource :: Table.t(), State.t(), Context.t()}) ::
          {:ok, {[DocSpec.Core.BlockNote.Spec.Table.t()], State.t()}} | error()
  defp write_resource(
         {resource = %Table{}, state = %State{}, context = %Context{inline_mode?: false}}
       ) do
    with {:ok, {rows, state}} <-
           write_children({resource.children, state, context}, &write_resource/1) do
      # Normalize table structure to handle rowspan/colspan correctly
      normalized_rows = normalize_table_rows(rows)

      {:ok,
       {[
          %DocSpec.Core.BlockNote.Spec.Table{
            id: resource.id,
            content: %DocSpec.Core.BlockNote.Spec.Table.Content{rows: normalized_rows}
          }
        ], state}}
      |> add_extracted_blocks()
    end
  end

  @spec write_resource({resource :: TableRow.t(), State.t(), Context.t()}) ::
          {:ok, {[DocSpec.Core.BlockNote.Spec.Table.Content.row()], State.t()}} | error()
  defp write_resource(
         {resource = %TableRow{}, state = %State{}, context = %Context{inline_mode?: false}}
       ) do
    with {:ok, {cells, state}} <-
           write_children({resource.children, state, context}, &write_resource/1) do
      {:ok, {[%{cells: cells}], state}}
    end
  end

  @spec write_resource({resource :: TableHeader.t(), State.t(), Context.t()}) ::
          {:ok, {[DocSpec.Core.BlockNote.Spec.Table.Cell.t()], State.t()}} | error()
  defp write_resource(
         {resource = %TableHeader{}, state = %State{}, context = %Context{inline_mode?: false}}
       ) do
    with {:ok, {bn_texts, state}} <-
           write_text_children(
             {resource.children, state, %Context{} = %{context | inline_mode?: true}},
             &write_resource/1
           ) do
      {:ok,
       {[
          %DocSpec.Core.BlockNote.Spec.Table.Cell{
            id: resource.id,
            content: bn_texts,
            props: %{
              colspan: resource.colspan,
              rowspan: resource.rowspan
            }
          }
        ], state}}
    end
  end

  @spec write_resource({resource :: TableCell.t(), State.t(), Context.t()}) ::
          {:ok, {[DocSpec.Core.BlockNote.Spec.Table.Cell.t()], State.t()}} | error()
  defp write_resource(
         {resource = %TableCell{}, state = %State{}, context = %Context{inline_mode?: false}}
       ) do
    with {:ok, {bn_texts, state}} <-
           write_text_children(
             {resource.children, state, %Context{} = %{context | inline_mode?: true}},
             &write_resource/1
           ) do
      {:ok,
       {[
          %DocSpec.Core.BlockNote.Spec.Table.Cell{
            id: resource.id,
            content: bn_texts,
            props: %{
              colspan: resource.colspan,
              rowspan: resource.rowspan
            }
          }
        ], state}}
    end
  end

  @spec write_resource({text :: Text.t(), State.t(), Context.t()}) ::
          {:ok, {[DocSpec.Core.BlockNote.Spec.Text.t()], State.t()}} | error()
  defp write_resource({text = %Text{}, state = %State{}, _context = %Context{}}) do
    {:ok,
     {[
        %DocSpec.Core.BlockNote.Spec.Text{
          text: text.text,
          styles: convert_styling(text.styles)
        }
      ], state}}
  end

  @spec write_resource({resource :: Link.t(), State.t(), Context.t()}) ::
          {:ok, {[DocSpec.Core.BlockNote.Spec.Link.t()], State.t()}} | error()
  defp write_resource({resource = %Link{}, state = %State{}, _context = %Context{}}) do
    {:ok,
     {[
        %DocSpec.Core.BlockNote.Spec.Link{
          id: resource.id,
          content: [
            %DocSpec.Core.BlockNote.Spec.Text{
              text: resource.text
            }
          ],
          href: resource.uri
        }
      ], state}}
  end

  defp write_resource(
         {%{children: children}, state = %State{}, context = %Context{inline_mode?: true}}
       ),
       do: write_children({children, state, context}, &write_resource/1)

  # Fallbacks for unsupported stuff.
  defp write_resource({%FootnoteReference{}, state = %State{}, _ctx}),
    do: {:ok, {[], state}}

  defp write_resource(
         {%DefinitionList{children: children}, state = %State{}, context = %Context{}}
       ),
       do: write_children({children, state, context}, &write_resource/1)

  defp write_resource({term = %DefinitionTerm{}, state = %State{}, context = %Context{}}),
    do:
      write_resource(
        {%Paragraph{
           id: term.id,
           children: term.children,
           text_alignment: nil
         }, state, context}
      )

  defp write_resource({details = %DefinitionDetails{}, state = %State{}, context = %Context{}}),
    do:
      write_resource(
        {%Paragraph{
           id: details.id,
           children: details.children,
           text_alignment: nil
         }, state, context}
      )

  defp write_resource({resource, _state, %Context{strict?: true}}),
    do: {:error, %UnsupportedResource{resource: resource}}

  defp write_resource({_, state, _context}),
    do: {:ok, {[], state}}

  @spec set_text_alignment(props, resource :: struct()) :: props
        when props: map()
  defp set_text_alignment(props, resource) when is_map(props) do
    text_alignment = Map.get(resource, :text_alignment)

    if text_alignment in ["right", "center", "justify"] do
      Map.put(props, :text_alignment, text_alignment)
    else
      props
    end
  end

  # Normalizes table rows by ensuring all rows have equal total colspan
  # and setting all rowspan values to 1. BlockNote's table implementation
  # doesn't properly support rowspan (cells spanning multiple rows), which
  # can cause rendering issues or validation errors. By setting all rowspan
  # to 1, we ensure tables render correctly even if the source document
  # specified rowspan values.
  @spec normalize_table_rows([DocSpec.Core.BlockNote.Spec.Table.Content.row()]) :: [
          DocSpec.Core.BlockNote.Spec.Table.Content.row()
        ]
  defp normalize_table_rows(rows) do
    # Calculate total colspan for each row
    row_colspans =
      Enum.map(rows, fn row ->
        Enum.reduce(row.cells, 0, fn cell, acc ->
          acc + (cell.props[:colspan] || 1)
        end)
      end)

    # Find max colspan across all rows
    max_colspan =
      case row_colspans do
        [] -> 0
        list -> Enum.max(list)
      end

    # Adjust each row to have max_colspan and set all rowspan to 1
    Enum.zip(rows, row_colspans)
    |> Enum.map(fn {row, current_colspan} ->
      colspan_diff = max_colspan - current_colspan

      # Normalize cells: fix colspan on last cell and set rowspan to 1
      normalized_cells =
        if colspan_diff > 0 and row.cells != [] do
          [last_cell | rest_cells] = Enum.reverse(row.cells)
          current_last_colspan = last_cell.props[:colspan] || 1

          updated_last_cell =
            put_in(last_cell.props[:colspan], current_last_colspan + colspan_diff)

          Enum.reverse([updated_last_cell | rest_cells])
        else
          row.cells
        end

      # Set all rowspan values to 1 to avoid occupancy grid conflicts
      normalized_rowspan_cells =
        Enum.map(normalized_cells, fn cell ->
          put_in(cell.props[:rowspan], 1)
        end)

      %{cells: normalized_rowspan_cells}
    end)
  end

  @spec convert_styling(styles :: Styles.t() | nil) :: DocSpec.Core.BlockNote.Spec.Text.Styles.t()
  defp convert_styling(nil), do: %{}

  defp convert_styling(styles = %Styles{}) do
    base_styling =
      %{}
      |> maybe_add_style(:italic, styles.italic)
      |> maybe_add_style(:bold, styles.bold)
      |> maybe_add_style(:underline, styles.underline)
      |> maybe_add_style(:strike, styles.strikethrough)

    base_styling
    |> maybe_add_color(:text_color, styles.text_color)
    |> maybe_add_color(:background_color, styles.highlight_color)
  end

  defp maybe_add_style(styling, _key, false), do: styling
  defp maybe_add_style(styling, _key, nil), do: styling
  defp maybe_add_style(styling, key, true), do: Map.put(styling, key, true)

  defp maybe_add_color(styling, _key, nil), do: styling

  defp maybe_add_color(styling, key, %DocSpec.Spec.HexColor{hex: hex}) do
    color_name = nearest_color(color_type(key), hex)

    if is_nil(color_name) do
      styling
    else
      Map.put(styling, key, color_name)
    end
  end

  defp color_type(:text_color), do: :text
  defp color_type(:background_color), do: :background

  @spec nearest_color(type :: :text | :background, color :: String.t()) :: Color.name() | nil
  defp nearest_color(type, color)
       when is_binary(color)
       when type == :background or type == :text do
    with {:ok, rgb} <- RGB.Hex.to_rgb(color),
         false <- rgb == {0, 0, 0},
         {:ok, name} <- Color.nearest(type, rgb) do
      name
    else
      _ -> nil
    end
  end

  @spec write_children(
          {children :: [child], State.t(), Context.t()},
          ({child, State.t(), Context.t()} -> {:ok, {[result], State.t()}} | error())
        ) ::
          {:ok, {[result], State.t()}} | error()
        when child: var, result: var

  defp write_children({children, state = %State{}, context = %Context{}}, write_fn) do
    Enum.reduce(
      children,
      {:ok, {[], state}},
      fn
        child, {:ok, {contents, state}} ->
          with {:ok, {content, state}} <- write_fn.({child, state, context}) do
            {:ok, {content ++ contents, state}}
          end

        _, {:error, reason} ->
          {:error, reason}
      end
    )
  end

  @spec write_text_children(
          {children :: [child], State.t(), Context.t()},
          ({child, State.t(), Context.t()} -> {:ok, {[result], State.t()}} | error())
        ) ::
          {:ok, {[result], State.t()}} | error()
        when child: var, result: var
  defp write_text_children({children, state = %State{}, context = %Context{}}, write_fn) do
    Enum.reduce(
      children,
      {:ok, {[], state}},
      fn
        %Paragraph{children: children}, {:ok, {contents, state}} ->
          with {:ok, {content, state}} <-
                 write_children(
                   {children, state, %Context{} = %{context | inline_mode?: true}},
                   write_fn
                 ) do
            {:ok, {content ++ contents, state}}
          end

        # Handle inline content (Text, Link) - keep in contents
        resource = %mod{}, {:ok, {contents, state}}
        when mod in [Text, Link] ->
          with {:ok, {inline_content, state}} <-
                 write_resource({resource, state, %Context{} = %{context | inline_mode?: true}}) do
            {:ok, {inline_content ++ contents, state}}
          end

        # Handle block-level elements - extract as separate blocks
        resource, {:ok, {contents, state}} ->
          with {:ok, {block_contents, state}} <-
                 write_resource({resource, state, %Context{} = %{context | inline_mode?: false}}) do
            {:ok,
             {contents,
              %State{} = %{
                state
                | extracted_blocks: block_contents ++ state.extracted_blocks
              }}}
          end

        _, {:error, reason} ->
          {:error, reason}
      end
    )
  end

  @spec add_extracted_blocks({[DocSpec.Core.BlockNote.Spec.Document.content()], State.t()}) ::
          {[DocSpec.Core.BlockNote.Spec.Document.content()], State.t()}
  @spec add_extracted_blocks({:ok, {[DocSpec.Core.BlockNote.Spec.Document.content()], State.t()}}) ::
          {:ok, {[DocSpec.Core.BlockNote.Spec.Document.content()], State.t()}}
  defp add_extracted_blocks({blocks, state = %State{}}) when is_list(blocks),
    do: {state.extracted_blocks ++ blocks, %State{} = %{state | extracted_blocks: []}}

  defp add_extracted_blocks({:ok, {blocks, state = %State{}}}) when is_list(blocks),
    do: {:ok, add_extracted_blocks({blocks, state})}

  @spec reverse(content) :: content when content: term()
  defp reverse(content) when is_list(content),
    do:
      content
      |> Enum.map(&reverse/1)
      |> Enum.reverse()

  defp reverse(resource = %{content: content}) when is_list(content) or is_map(content),
    do: Map.put(resource, :content, reverse(content))

  defp reverse(resource = %{rows: rows}) when is_list(rows),
    do: Map.put(resource, :rows, reverse(rows))

  defp reverse(resource = %{cells: cells}) when is_list(cells),
    do: Map.put(resource, :cells, reverse(cells))

  defp reverse(other),
    do: other
end
