defmodule RiftStandaloneExample.CaseTypes.AccessChange do
  @moduledoc false

  use Rift.CaseType

  @impl true
  def type, do: :access_change

  @impl true
  def title, do: "Access change"

  @impl true
  def description, do: "Request an operator review before changing access."

  @impl true
  def team, do: "admin"

  @impl true
  def fields do
    [
      field(:target_user_id, :select,
        label: "User",
        required: true,
        options: {:resolver, :target_user_id}
      ),
      field(:role, :select,
        label: "Role",
        required: true,
        options: [{"Operator", "operator"}, {"Admin", "admin"}]
      ),
      field(:reason, :textarea,
        label: "Reason",
        required: true
      )
    ]
  end

  @impl true
  def workflow, do: RiftStandaloneExample.Workflows.AccessChange

  @impl true
  def trigger, do: :submit

  @impl true
  def build_payload(attrs, ctx) do
    %{
      target_user_id: attrs.target_user_id,
      role: attrs.role,
      reason: attrs.reason,
      opened_by: ctx.actor.id
    }
  end
end
