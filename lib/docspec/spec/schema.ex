defmodule DocSpec.Spec.Schema do
  @moduledoc """
  This module sets some defaults over the Ecto schema for the DocSpec spec.

  1. Use this in all schemas for the DocSpec spec, instead of `use Ecto.Schema` or `use TypedEctoSchema`:
      `use DocSpec.Spec.Schema, type: "https://alpha.docspec.io/Foo"`
  2. Implement the `changeset/2` function in the schema module.
  3. Make sure to add `@cast_opts` to all calls to `cast/4` or `cast_embed/3` or `cast_polymorphic_embed/3`,
     as it ensures strings that only contain whitespace are accepted as valid.

  Note: the `type` option is required and must be a string. It is the resource type of the schema.
  It will be available as `@resource_type` in the schema module and through the `resource_type/0` function on the schema module.
  """

  defmacro __using__(opts) do
    # coveralls-ignore-next-line This is a macro, so it is only executed at compile-time.
    {opts, ecto_opts} = parse_opts(opts)

    quote location: :keep do
      use TypedEctoSchema, unquote(ecto_opts)
      import Ecto.Changeset
      import PolymorphicEmbed
      import DocSpec.Spec.Schema, only: [map: 1, validate_url: 1]

      @primary_key false

      # This function must be implemented in the using module.
      @spec changeset(struct(), map()) :: Ecto.Changeset.t()

      # This must be passed to all calls to cast/4, as it ensures strings
      # that only contain whitespace are accepted as valid.
      @cast_opts [empty_values: []]

      # This makes the `type` argument available inside and outside of the schema module.
      @resource_type unquote(opts[:type])
      def resource_type, do: @resource_type

      # This defines the constructor functions for the schema module.
      @before_compile {DocSpec.Spec.Schema, :def_constructor}

      # This defines the Jason.Encoder implementation for the schema module.
      @before_compile {DocSpec.Spec.Schema, :def_json_encoder}

      @doc """
      Validates that the :id field contains a valid UUID.
      Uses `Ecto.UUID.cast/1` which aligns with the JSON Schema `format: "uuid"`.

      ## Example

          def changeset(schema, attrs) do
            schema
            |> cast(attrs, [:id, :type], @cast_opts)
            |> validate_required([:id])
            |> validate_uuid()
          end
      """
      @spec validate_uuid(Ecto.Changeset.t()) :: Ecto.Changeset.t()
      def validate_uuid(changeset) do
        validate_change(changeset, :id, fn :id, value ->
          case Ecto.UUID.cast(value) do
            {:ok, _} -> []
            :error -> [id: {"is not a valid UUID", [validation: :uuid]}]
          end
        end)
      end

      @doc """
      This validation function can be used in `changeset/2` implementations to ensure that
      the value for a specific field is a valid URL.

      ## Options

      * `:message` - The error message to use when the URL is invalid.
      * `:allow_relative` - If set to `true`, relative URLs are allowed. Default is `false`.
      """
      @type validate_url_opt() :: {:message, String.t()} | {:allow_relative, boolean()}
      @spec validate_url(Ecto.Changeset.t(), atom(), [validate_url_opt()]) :: Ecto.Changeset.t()
      def validate_url(changeset, field, opts \\ []) do
        validate_change(changeset, field, fn ^field, url ->
          case DocSpec.Spec.Schema.validate_url(url, Keyword.drop(opts, [:message])) do
            nil -> []
            error -> [{field, Keyword.get(opts, :message, error)}]
          end
        end)
      end
    end
  end

  defp parse_opts(opts) do
    # coveralls-ignore-start This is part of a macro, so it is only executed at compile-time.
    if not is_nil(opts[:type]) and (!is_binary(opts[:type]) or opts[:type] == "") do
      raise """
      \n
      A #{IO.ANSI.yellow()}type#{IO.ANSI.reset()} option must be passed to #{IO.ANSI.yellow()}use DocSpec.Spec.Schema#{IO.ANSI.reset()}.
      Example: #{IO.ANSI.yellow()}use DocSpec.Spec.Schema, type: "https://alpha.docspec.io/Foo"
      #{IO.ANSI.reset()}
      """
    end

    ecto_opts = Keyword.delete(opts, :type)
    {opts, ecto_opts}
    # coveralls-ignore-stop
  end

  @doc """
  This macro defines the `new/1` and `new!/1` functions for the schema module that create a new document from a template,
  which essentially functions like an input-validating constructor for the struct defined by the schema module.
  """
  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  defmacro def_constructor(_) do
    # coveralls-ignore-next-line This is part of a macro, so it is only executed at compile-time.
    full_module_name =
      quote do
        __MODULE__ |> to_string() |> String.split(".") |> List.delete_at(0) |> Enum.join(".")
      end

    # coveralls-ignore-next-line This is part of a macro, so it is only executed at compile-time.
    module_name =
      quote do
        __MODULE__ |> to_string() |> String.split(".") |> List.last()
      end

    quote location: :keep,
          bind_quoted: [full_module_name: full_module_name, module_name: module_name] do
      @doc """
      This function creates a new `#{full_module_name}` struct from a map of keys and values, where the keys are snake_case.
      Returns a tuple with either `{:ok, #{Macro.underscore(module_name)}}` or `{:error, changeset}`.

      Note: If you want to use a map with camelCase keys, use `DocSpec.Spec.Schema.decode_keys/1`
      to convert them to snake_case before passing them to the constructor.
      """
      @spec new() :: {:ok, __MODULE__.t()} | {:error, Ecto.Changeset.t()}
      @spec new(map()) :: {:ok, __MODULE__.t()} | {:error, Ecto.Changeset.t()}
      def new(template \\ %{type: @resource_type})

      def new(template = %{type: @resource_type}) do
        changeset = changeset(%__MODULE__{}, template)

        if changeset.valid? do
          document = Ecto.Changeset.apply_changes(changeset)
          {:ok, document}
        else
          {:error, changeset}
        end
      end

      def new(template = %{"type" => @resource_type}) do
        changeset = changeset(%__MODULE__{}, template)

        if changeset.valid? do
          document = Ecto.Changeset.apply_changes(changeset)
          {:ok, document}
        else
          {:error, changeset}
        end
      end

      def new(template = %{type: type}) when is_nil(type) do
        {:error, %Ecto.Changeset{valid?: false, errors: [type: {"is missing", [type: type]}]}}
      end

      def new(template = %{type: type}) do
        {:error, %Ecto.Changeset{valid?: false, errors: [type: {"is invalid", [type: type]}]}}
      end

      def new(template = %{"type" => type}) when is_nil(type) do
        {:error, %Ecto.Changeset{valid?: false, errors: [type: {"is missing", [type: type]}]}}
      end

      def new(template = %{"type" => type}) do
        {:error, %Ecto.Changeset{valid?: false, errors: [type: {"is invalid", [type: type]}]}}
      end

      if is_nil(@resource_type) do
        def new(template = %{}) do
          changeset = changeset(%__MODULE__{}, template)

          if changeset.valid? do
            document = Ecto.Changeset.apply_changes(changeset)
            {:ok, document}
          else
            {:error, changeset}
          end
        end
      end

      def new(template = %{}) do
        {:error, %Ecto.Changeset{valid?: false, errors: [type: {"is missing", [type: nil]}]}}
      end

      def new(template) do
        {:error,
         %Ecto.Changeset{
           valid?: false,
           errors: [template: {"is expected to be a map", [actual_type: Useful.typeof(template)]}]
         }}
      end

      @doc """
      This function creates a new `#{full_module_name}` struct from a map of keys and values, where the keys are snake_case.
      Returns the `#{Macro.underscore(module_name)}}` object or raises an `Ecto.CastError`.

      Note: If you want to use a map with camelCase keys, use `DocSpec.Spec.Schema.decode_keys/1`
      to convert them to snake_case before passing them to the constructor.
      """
      @spec new!() :: __MODULE__.t()
      @spec new!(map()) :: __MODULE__.t()
      def new!(template \\ %{type: @resource_type}) do
        case new(template) do
          {:ok, document} -> document
          # TODO: Be more descriptive of what the error is? Something with DocSpec.Spec.Schema.collect_errors/1
          {:error, changeset} -> raise Ecto.CastError, type: __MODULE__, value: template
        end
      end
    end
  end

  @doc """
  Returns true if the given module is an existing module.
  """
  @spec module_exists?(module()) :: boolean()
  def module_exists?(module),
    do: Code.ensure_loaded?(module) and function_exported?(module, :__info__, 1)

  @doc """
  Returns true for a module that is a schema module, i.e. it has a `new/1` and a `changeset/2` function.
  """
  @spec schema_module?(module()) :: boolean()
  def schema_module?(module) when is_atom(module),
    do:
      module |> Code.ensure_compiled!() |> Code.ensure_loaded?() and
        function_exported?(module, :new, 1) and
        function_exported?(module, :changeset, 2)

  def schema_module?(_), do: false

  @doc """
  This macro maps a list of modules to a list of tuples with the module's resource type and the module itself.
  It's a macro because Ecto's schema definitions require this mapping to be done at compile time.

  Example:

      > DocSpec.Spec.Schema.map([Heading, Image])
      [
        "https://alpha.docspec.io/Heading": Heading,
        "https://alpha.docspec.io/Image": Image
      ]
  """
  defmacro map(modules) do
    {resolved_modules, _} = Code.eval_quoted(modules, [], __CALLER__)

    for module <- resolved_modules do
      quote do
        {String.to_atom(unquote(module).resource_type()), unquote(module)}
      end
    end
  end

  @doc """
  This function validates whether a string is a valid URL, returning nil if it's valid
  and an `Ecto.Changeset.error()` if it's not.

  ## Examples

      iex> DocSpec.Spec.Schema.validate_url("http://localhost:4000")
      nil

      iex> DocSpec.Spec.Schema.validate_url("https://docspec.io/path/to/resource?query=string#fragment")
      nil

      iex> DocSpec.Spec.Schema.validate_url("https://no-tld")
      nil

      iex> DocSpec.Spec.Schema.validate_url("test")
      {"is not a valid URL", error: [invalid_scheme: nil]}

      iex> DocSpec.Spec.Schema.validate_url("/path/to/resource")
      {"is not a valid URL", error: [invalid_scheme: nil, invalid_host: "/path/to/resource"]}
  """
  @type validate_url_opt() :: {:allow_relative, boolean()}
  @spec validate_url(String.t(), [validate_url_opt()]) :: Ecto.Changeset.error() | nil
  def validate_url(url, opts \\ []) do
    case URI.new(url) |> validate_uri(opts) do
      [] -> nil
      errors -> {"is not a valid URL", error: errors}
    end
  end

  defp validate_uri({:error, invalid_part}, _) do
    [{:invalid_part, invalid_part}]
  end

  defp validate_uri({:ok, %URI{scheme: scheme, host: host, path: path}}, opts) do
    allow_relative = opts |> Keyword.get(:allow_relative, false)

    if allow_relative do
      validate_host(host, path)
    else
      validate_scheme(scheme) ++ validate_host(host, path)
    end
  end

  defp validate_scheme("http"), do: []
  defp validate_scheme("https"), do: []
  defp validate_scheme("ftp"), do: []
  defp validate_scheme("data"), do: []
  defp validate_scheme("mailto"), do: []
  defp validate_scheme(scheme), do: [{:invalid_scheme, scheme}]

  defp validate_host(host, path \\ nil)
  defp validate_host(nil, nil), do: [{:invalid_host, nil}]
  defp validate_host(nil, path), do: validate_host(path)
  defp validate_host(host = "/" <> _rest, _), do: [{:invalid_host, host}]
  defp validate_host("", _), do: [{:invalid_host, ""}]
  defp validate_host(_, _), do: []

  @type errors() :: %{(property :: atom()) => Ecto.Changeset.error()}

  @doc """
  Collects all errors from a changeset and its nested changesets into a flat map,
  mapping the full JSON path of each property to its error.

  ## Example

      iex> changeset = %Ecto.Changeset{
      ...>   changes: [
      ...>     descriptors: [
      ...>       %Ecto.Changeset{errors: [url: {"is invalid", [validation: :invalid_url]}]}
      ...>     ]
      ...>   ],
      ...>   errors: [
      ...>     name: {"is invalid", [type: :string]}
      ...>   ]
      ...> }
      iex> DocSpec.Spec.Schema.collect_errors(changeset)
      %{
        name: {"is invalid", [type: :string]},
        "descriptors[0].url": {"is invalid", [validation: :invalid_url]}
      }
  """
  @spec collect_errors(Ecto.Changeset.t()) :: errors()
  def collect_errors(changeset = %Ecto.Changeset{}) do
    collect_errors(changeset, :"")
    |> Map.new(fn {field, error} ->
      {field |> Atom.to_string() |> String.trim_leading(".") |> String.to_atom(), error}
    end)
  end

  @spec collect_errors(Ecto.Changeset.t(), parent :: atom() | String.t()) :: errors()
  def collect_errors(%Ecto.Changeset{changes: changes, errors: errors}, parent) do
    child_errors =
      changes
      |> Enum.flat_map(fn
        {field, changeset} when changeset |> is_struct(Ecto.Changeset) ->
          collect_errors(changeset, field)

        {field, value} when value |> is_list() ->
          collect_errors(value, field)

        _ ->
          []
      end)
      |> Map.new()

    errors
    |> Map.new()
    |> Map.merge(child_errors)
    |> Map.new(fn {field, error} -> {:"#{parent}.#{field}", error} end)
  end

  @spec collect_errors([Ecto.Changeset.t() | any()], parent :: atom() | String.t()) :: errors()
  def collect_errors(list, parent) when list |> is_list() do
    list
    |> Enum.with_index(fn
      changeset = %Ecto.Changeset{}, index -> collect_errors(changeset, "#{parent}[#{index}]")
      _, _ -> %{}
    end)
    |> Enum.reduce(&Map.merge/2)
  end

  @doc """
  Defines the Jason.Encoder implementation for a schema module.

  This encoder omits fields that have their default values, producing minimal JSON output.
  Nested structs are handled recursively, and empty objects (from all-default nested structs)
  are also omitted.
  """
  defmacro def_json_encoder(_) do
    quote location: :keep do
      defimpl Jason.Encoder, for: __MODULE__ do
        def encode(struct, opts) do
          struct
          |> DocSpec.JSON.to_encodable()
          |> Jason.Encode.map(opts)
        end
      end
    end
  end

  # ============================================================================
  # JSON Encoding/Decoding - delegates to DocSpec.JSON
  # These are kept here for backwards compatibility.
  # ============================================================================

  @doc """
  Encodes a struct to a map, omitting fields that have their default values
  and converting keys to camelCase.

  Delegates to `DocSpec.JSON.to_encodable/1`.

  ## Examples

      iex> styles = %DocSpec.Spec.Styles{bold: false, italic: false}
      iex> DocSpec.Spec.Schema.encode_without_defaults(styles)
      %{}

      iex> styles = %DocSpec.Spec.Styles{bold: true, italic: false}
      iex> DocSpec.Spec.Schema.encode_without_defaults(styles)
      %{"bold" => true}

      iex> text = %DocSpec.Spec.Text{id: "123", text: "hello", styles: %DocSpec.Spec.Styles{text_color: "#ff0000"}}
      iex> DocSpec.Spec.Schema.encode_without_defaults(text)
      %{"id" => "123", "type" => "https://alpha.docspec.io/Text", "text" => "hello", "styles" => %{"textColor" => "#ff0000"}}

  """
  @spec encode_without_defaults(struct() | list() | any()) :: map() | list() | any()
  defdelegate encode_without_defaults(value), to: DocSpec.JSON, as: :to_encodable

  @doc """
  Converts a snake_case atom or string to a camelCase string.

  Delegates to `DocSpec.JSON.to_camel_case/1`.

  ## Examples

      iex> DocSpec.Spec.Schema.to_camel_case(:text_color)
      "textColor"

      iex> DocSpec.Spec.Schema.to_camel_case(:id)
      "id"

      iex> DocSpec.Spec.Schema.to_camel_case("highlight_color")
      "highlightColor"

  """
  @spec to_camel_case(atom() | String.t()) :: String.t()
  defdelegate to_camel_case(key), to: DocSpec.JSON

  @doc """
  Converts a camelCase string to a snake_case atom.

  Delegates to `DocSpec.JSON.to_snake_case/1`.

  ## Examples

      iex> DocSpec.Spec.Schema.to_snake_case("textColor")
      :text_color

      iex> DocSpec.Spec.Schema.to_snake_case("id")
      :id

      iex> DocSpec.Spec.Schema.to_snake_case("highlightColor")
      :highlight_color

  """
  @spec to_snake_case(String.t() | atom()) :: atom()
  defdelegate to_snake_case(key), to: DocSpec.JSON

  @doc """
  Decodes a JSON string to a map with snake_case atom keys.

  Delegates to `DocSpec.JSON.decode/1`.

  ## Examples

      iex> DocSpec.Spec.Schema.decode_json(~s({"textColor": "#ff0000", "highlightColor": null}))
      {:ok, %{text_color: "#ff0000", highlight_color: nil}}

      iex> DocSpec.Spec.Schema.decode_json(~s({"children": [{"type": "text"}]}))
      {:ok, %{children: [%{type: "text"}]}}

  """
  @spec decode_json(String.t()) :: {:ok, map()} | {:error, Jason.DecodeError.t()}
  defdelegate decode_json(json), to: DocSpec.JSON, as: :decode

  @doc """
  Decodes a JSON string to a map with snake_case atom keys.
  Raises on invalid JSON.

  Delegates to `DocSpec.JSON.decode!/1`.

  ## Examples

      iex> DocSpec.Spec.Schema.decode_json!(~s({"textColor": "#ff0000"}))
      %{text_color: "#ff0000"}

  """
  @spec decode_json!(String.t()) :: map()
  defdelegate decode_json!(json), to: DocSpec.JSON, as: :decode!

  @doc """
  Converts a map or list with camelCase string keys to snake_case atom keys.

  Delegates to `DocSpec.JSON.from_decoded/1`.

  ## Examples

      iex> DocSpec.Spec.Schema.decode_keys(%{"textColor" => "#ff0000"})
      %{text_color: "#ff0000"}

      iex> DocSpec.Spec.Schema.decode_keys([%{"assetId" => "123"}])
      [%{asset_id: "123"}]

  """
  @spec decode_keys(map() | list() | any()) :: map() | list() | any()
  defdelegate decode_keys(value), to: DocSpec.JSON, as: :from_decoded
end
