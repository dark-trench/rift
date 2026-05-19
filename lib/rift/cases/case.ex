defmodule Rift.Cases.Case do
  @moduledoc """
  Persisted human-facing Rift case.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Rift.Cases.Event

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @type t :: %__MODULE__{}

  @statuses ~w(
    draft
    open
    running
    waiting_for_approval
    approved
    rejected
    cancelled
    failed
    side_effect_failed
    completed
  )

  schema "rift_cases" do
    field :tenant_key, :string
    field :type, :string
    field :subject, :string
    field :status, :string
    field :team, :string
    field :opened_by_ref, :string
    field :assignee_ref, :string
    field :state, :map, default: %{}
    field :details, :map, default: %{}
    field :squid_mesh_run_id, Ecto.UUID

    has_many :events, Event, foreign_key: :case_id

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(rift_case, attrs) do
    rift_case
    |> cast(attrs, [
      :tenant_key,
      :type,
      :subject,
      :status,
      :team,
      :opened_by_ref,
      :assignee_ref,
      :state,
      :details,
      :squid_mesh_run_id
    ])
    |> validate_required([:type, :subject, :status, :opened_by_ref])
    |> validate_inclusion(:status, @statuses)
  end
end
