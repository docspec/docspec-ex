defmodule DocSpec.Core.Validation.Writer.Rules.DefinitionTermHasDefinitionDetails do
  @moduledoc """
  This rule validates that each DefinitionTerm in a DefinitionList is followed by a DefinitionDetails.
  """
  alias DocSpec.Core.Validation.Writer.{Severity, State}
  alias DocSpec.Spec.{DefinitionDetails, DefinitionList, DefinitionTerm}

  use DocSpec.Core.Validation.Writer.Rule,
    severity: Severity.error(),
    rule: "definition-term-has-definition-details",
    ruleset: "https://validation.spec.docspec.io/",
    # @TODO set `ruleset_version` to a real version
    ruleset_version: "unknown",
    validates: [DefinitionDetails, DefinitionList, DefinitionTerm]

  @impl true
  # Set the current id of the DefinitionTerm.
  def update_state(state = %State{}, %DefinitionTerm{id: id}),
    do: state |> State.set(:definition_term_id_without_details, id)

  # The previous one has details if it is followed by a DefinitionDetails.
  # Set to nil if the current one is a DefinitionTerm or DefinitionList.
  def update_state(state = %State{}, _),
    do: state |> State.set(:definition_term_id_without_details, nil)

  # If two definition terms directly follow up on eachother, the previous
  # one has no details. Therefore set a finding for the previous one.
  @impl true
  def validate(
        resource = %DefinitionTerm{},
        state = %State{definition_term_id_without_details: id}
      )
      when not is_nil(id),
      do:
        state
        |> State.prepend(:findings, make_finding(id))
        |> update_state(resource)

  def validate(resource, state = %State{}),
    do: state |> update_state(resource)
end
