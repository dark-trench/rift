defmodule Rift.Cases.Event do
  @moduledoc """
  Immutable timeline event for a Rift case.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Rift.Cases.Case

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @type t :: %__MODULE__{}

  @event_types ~w(
    case_opened
    comment_added
    attachment_referenced
    workflow_started
    case_claimed
    case_released
    case_assigned
    case_approved
    case_rejected
    case_cancelled
    side_effect_completed
    side_effect_failed
    system_note
  )

  schema "rift_case_events" do
    field :tenant_key, :string
    field :actor_ref, :string
    field :type, :string
    field :data, :map, default: %{}
    field :visible_to_originator, :boolean, default: false

    belongs_to :case, Case

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(event, attrs) do
    event
    |> cast(attrs, [
      :case_id,
      :tenant_key,
      :actor_ref,
      :type,
      :data,
      :visible_to_originator
    ])
    |> validate_required([:case_id, :type])
    |> validate_inclusion(:type, @event_types)
    |> foreign_key_constraint(:case_id)
  end
end
