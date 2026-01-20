defmodule DocSpec.Core.Validation.Writer do
  @moduledoc """
  DocSpec Validation provides accessibility validation for DocSpec documents.
  TODO: proper description
  """
  alias DocSpec.Core.Validation.Spec.Finding
  alias DocSpec.Core.Validation.Writer.State

  @rules [
    DocSpec.Core.Validation.Writer.Rules.DefinitionListHasDefinitionTerm,
    DocSpec.Core.Validation.Writer.Rules.DefinitionTermHasDefinitionDetails,
    DocSpec.Core.Validation.Writer.Rules.EmptyDefinitionDetails,
    DocSpec.Core.Validation.Writer.Rules.EmptyDefinitionTerm,
    DocSpec.Core.Validation.Writer.Rules.EmptyHeading,
    DocSpec.Core.Validation.Writer.Rules.EmptyTableHeader,
    DocSpec.Core.Validation.Writer.Rules.HeadingLevelValid,
    DocSpec.Core.Validation.Writer.Rules.HeadingOrder,
    DocSpec.Core.Validation.Writer.Rules.ImageMustHaveAlt,
    DocSpec.Core.Validation.Writer.Rules.LinkName,
    DocSpec.Core.Validation.Writer.Rules.NoUnderline,
    DocSpec.Core.Validation.Writer.Rules.PAsHeading,
    DocSpec.Core.Validation.Writer.Rules.PageHasHeadingOne,
    DocSpec.Core.Validation.Writer.Rules.PageHasMultipleHeadingOne,
    DocSpec.Core.Validation.Writer.Rules.PageStartsWithHeadingOne,
    DocSpec.Core.Validation.Writer.Rules.StyleBoldInHeading,
    DocSpec.Core.Validation.Writer.Rules.StyleItalicInHeading,
    DocSpec.Core.Validation.Writer.Rules.TableNeedsMultipleRows
  ]

  # Mapping from resource types to their applicable rules
  @rules_by_type Enum.reduce(@rules, %{}, fn rule, acc ->
                   Enum.reduce(rule.validates(), acc, fn type, acc ->
                     Map.update(acc, type, [rule], &[rule | &1])
                   end)
                 end)

  @spec validate(DocSpec.Spec.object() | [DocSpec.Spec.object()]) :: [Finding.t()]
  @spec validate(DocSpec.Spec.object() | [DocSpec.Spec.object()], State.t()) :: State.t()

  def validate(resource),
    do: resource |> validate(%State{}) |> State.get(:findings)

  def validate(resources, state = %State{}) when is_list(resources),
    do: resources |> Enum.reduce(state, fn resource, state -> resource |> validate(state) end)

  def validate(resource = %{children: children}, state = %State{}),
    do: children |> validate(resource |> validate_resource(state))

  def validate(resource, state = %State{}),
    do: resource |> validate_resource(state)

  for {type, rules} <- @rules_by_type do
    defp validate_resource(resource = %{__struct__: unquote(type)}, state = %State{}),
      do:
        unquote(rules) |> Enum.reduce(state, fn rule, state -> rule.validate(resource, state) end)
  end

  defp validate_resource(_, state),
    do: state
end
