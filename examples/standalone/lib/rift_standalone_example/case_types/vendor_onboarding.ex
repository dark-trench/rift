defmodule RiftStandaloneExample.CaseTypes.VendorOnboarding do
  @moduledoc false

  use Rift.CaseType

  case_type do
    type :vendor_onboarding
    title "Vendor onboarding"
    description "Coordinate approvals before adding a new vendor."
    team "procurement"
    workflow RiftStandaloneExample.Workflows.VendorOnboarding
    trigger :submit

    fields do
      field :vendor_name, :text,
        label: "Vendor name",
        required: true

      field :category, :select,
        label: "Category",
        required: true,
        options: [
          {"Software", "software"},
          {"Services", "services"},
          {"Facilities", "facilities"}
        ]

      field :business_owner_id, :select,
        label: "Business owner",
        required: true,
        options: {:resolver, :business_owner_id}

      field :justification, :textarea,
        label: "Justification",
        required: true
    end
  end

  @impl true
  def build_payload(attrs, ctx) do
    %{
      vendor_name: attrs.vendor_name,
      category: attrs.category,
      business_owner_id: attrs.business_owner_id,
      justification: attrs.justification,
      opened_by: ctx.actor.id
    }
  end
end
