defmodule DocSpec.Core.Validation.Writer.Rule do
  @moduledoc """
  This module provides a macro for defining validation rules for DocSpec spec objects, i.e. documents and their elements.
  Such rules check for semantic correctness and accessibility concerns in the spec objects.

  Simply `use DocSpec.Core.Validation.Writer.Rule` in your module with all details about the validation rule and implement the `valid?/1`
  function to determine whether the spec objects that this rule validates, are valid.

  You may also choose to override the `validates/0` and `make_finding/1` functions for more granular control over the
  validation process.

  If your validation rule requires state to be maintained during the validation process, implement an `update_state/2` function
  to update the `DocSpec.Core.Validation.Writer.State` struct with the necessary information.

  Note that the application of and merging of autofixes to a document as a result of validation is currently not implemented.

  Example:

      defmodule DocSpec.Core.Validation.Writer.Rules.HeadingLevelValid do
        use DocSpec.Core.Validation.Writer.Rule,
          severity: DocSpec.Core.Validation.Writer.Severity.error(),
          rule: "invalid-heading-level",
          ruleset: "https://html.spec.whatwg.org/",
          ruleset_version: "5",
          validates: [DocSpec.Spec.Heading]

        @impl true
        def valid?(%DocSpec.Spec.Heading{level: level}, _),
          do: level >= 1 and level <= 6
      end
  """

  alias DocSpec.Core.Validation.Spec.Finding
  alias DocSpec.Core.Validation.Writer.Severity

  @callback make_finding(resource_id :: String.t()) :: Finding.t()
  @callback validates() :: [module()]
  @callback valid?(DocSpec.Spec.object(), DocSpec.Core.Validation.Writer.State.t()) :: boolean()
  @callback validate(DocSpec.Spec.object(), DocSpec.Core.Validation.Writer.State.t()) ::
              DocSpec.Core.Validation.Writer.State.t()
  @callback update_state(DocSpec.Core.Validation.Writer.State.t(), DocSpec.Spec.object()) ::
              DocSpec.Core.Validation.Writer.State.t()

  @type t :: module()

  @type opt() ::
          {:severity, Severity.t()}
          | {:rule, String.t()}
          | {:ruleset, String.t()}
          | {:ruleset_version, String.t()}
          | {:validates, [module()]}

  @spec __using__([opt()]) :: Macro.t()
  defmacro __using__(opts) do
    {severity, _} = opts |> Keyword.get(:severity) |> Code.eval_quoted([], __CALLER__)
    rule = opts |> Keyword.get(:rule)
    ruleset = opts |> Keyword.get(:ruleset)
    ruleset_version = opts |> Keyword.get(:ruleset_version)
    {validates, _} = opts |> Keyword.get(:validates) |> Code.eval_quoted([], __CALLER__)

    if severity not in Severity.values() do
      raise """
      Property :severity is required on `use DocSpec.Core.Validation.Writer.Rule` and must be one of #{inspect(Severity.values())}, but got #{inspect(severity)}.
      """
    end

    if not is_binary(rule) do
      raise """
      Property :rule is required on `use DocSpec.Core.Validation.Writer.Rule` and must be a string, but got #{inspect(rule)}.
      """
    end

    if not is_binary(ruleset) do
      raise """
      Property :ruleset is required on `use DocSpec.Core.Validation.Writer.Rule` and must be a string, but got #{inspect(ruleset)}.
      """
    end

    if not is_binary(ruleset_version) do
      raise """
      Property :ruleset_version is required on `use DocSpec.Core.Validation.Writer.Rule` and must be a string, but got #{inspect(ruleset_version)}.
      """
    end

    if not is_list(validates) or validates == [] or
         not Enum.all?(validates, &DocSpec.Spec.Schema.schema_module?/1) do
      message = """
      Property :validates is required on `use DocSpec.Core.Validation.Writer.Rule` and must be a non-empty list of DocSpec.Spec.* modules,
      but got #{inspect(validates)}.
      """

      message =
        if not is_list(validates) or validates == [] do
          """
          #{message}
          The :validates property determines which DocSpec Spec objects this rule validates.
          If that is not defined or an empty list, then this rule validates nothing.
          """
        else
          """
          #{message}
          Validation rules are only ever applied to DocSpec Spec objects, so in order for a rule to actually match those,
          :validates must contain valid DocSpec.Spec.* modules.

          The following entries are not valid DocSpec.Spec.* modules:
          - #{validates |> Enum.reject(&DocSpec.Spec.Schema.schema_module?/1) |> Enum.map_join("\n- ", &inspect/1)}
          """
        end

      raise message
    end

    quote do
      alias DocSpec.Core.Validation.Writer.State
      @behaviour DocSpec.Core.Validation.Writer.Rule

      @impl true
      def make_finding(resource_id) when is_binary(resource_id) do
        %Finding{
          resource_id: resource_id,
          severity: unquote(severity),
          rule: unquote(rule),
          ruleset: unquote(ruleset),
          ruleset_version: unquote(ruleset_version)
        }
      end

      @impl DocSpec.Core.Validation.Writer.Rule
      def validates,
        do: unquote(validates)

      @impl DocSpec.Core.Validation.Writer.Rule
      def validate(resource, state = %State{}) do
        if valid?(resource, state) do
          state
          |> update_state(resource)
        else
          state
          |> State.prepend(:findings, make_finding(resource.id))
          |> update_state(resource)
        end
      end

      # Note: `valid?` and `update_state` are defined here solely for `defoverridable`.
      #       Their default implementations are defined in the `__before_compile__` macro.

      @impl DocSpec.Core.Validation.Writer.Rule
      def valid?(_resource, _state = %State{}),
        do: true

      @impl DocSpec.Core.Validation.Writer.Rule
      def update_state(state = %State{}, resource),
        do: state

      defoverridable validates: 0, valid?: 2, validate: 2, update_state: 2

      @before_compile DocSpec.Core.Validation.Writer.Rule
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      alias DocSpec.Core.Validation.Writer.State

      @impl DocSpec.Core.Validation.Writer.Rule
      def valid?(_, _state = %State{}),
        do: true

      @impl DocSpec.Core.Validation.Writer.Rule
      def update_state(state = %State{}, _),
        do: state
    end
  end
end
