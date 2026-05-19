defmodule RiftStandaloneExample.CaseTypes.DataExport do
  @moduledoc false

  use Rift.CaseType

  case_type do
    type :data_export
    title "Data export"
    description "Request review before exporting sensitive workspace data."
    team "security"
    workflow RiftStandaloneExample.Workflows.DataExport
    trigger :submit

    fields do
      field :dataset, :select,
        label: "Dataset",
        required: true,
        options: [{"Users", "users"}, {"Billing", "billing"}, {"Audit events", "audit_events"}]

      field :destination, :text,
        label: "Destination",
        required: true,
        placeholder: "Secure bucket or ticket reference"

      field :retention_days, :number,
        label: "Retention days",
        required: true,
        default: "30"

      field :reason, :textarea,
        label: "Reason",
        required: true
    end
  end

  @impl true
  def build_payload(attrs, ctx) do
    %{
      dataset: attrs.dataset,
      destination: attrs.destination,
      retention_days: attrs.retention_days,
      reason: attrs.reason,
      opened_by: ctx.actor.id
    }
  end
end
