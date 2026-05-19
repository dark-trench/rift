defmodule RiftStandaloneExample.CaseTypes.AccessChange do
  @moduledoc false

  use Rift.CaseType

  case_type do
    type :access_change
    title "Access change"
    description "Request an operator review before changing access."
    team "admin"
    workflow RiftStandaloneExample.Workflows.AccessChange
    trigger :submit

    fields do
      field :target_user_id, :select,
        label: "User",
        required: true,
        options: {:resolver, :target_user_id}

      field :role, :select,
        label: "Role",
        required: true,
        options: [{"Operator", "operator"}, {"Admin", "admin"}]

      field :reason, :textarea,
        label: "Reason",
        required: true
    end
  end

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
