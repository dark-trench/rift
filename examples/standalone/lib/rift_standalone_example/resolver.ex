defmodule RiftStandaloneExample.Resolver do
  @moduledoc false

  @behaviour Rift.Resolver

  alias RiftStandaloneExample.CaseTypes.AccessChange

  @impl true
  def resolve_actor(_conn), do: %{id: "operator-1", operator?: true}

  @impl true
  def resolve_tenant(_actor), do: "example"

  @impl true
  def resolve_access(%{operator?: true}), do: :operator
  def resolve_access(_actor), do: :originator

  @impl true
  def resolve_case_types(_actor), do: [AccessChange]

  @impl true
  def resolve_select_options(_actor, AccessChange, :target_user_id) do
    [{"Ada Lovelace", "user-ada"}, {"Grace Hopper", "user-grace"}]
  end

  def resolve_select_options(_actor, _case_type, _field_name), do: []

  @impl true
  def resolve_actor_label("operator-1"), do: "Example Operator"
  def resolve_actor_label(actor_ref), do: to_string(actor_ref)

  @impl true
  def resolve_attachment_url("demo:" <> attachment_id), do: "/attachments/#{attachment_id}"
  def resolve_attachment_url(_attachment_ref), do: nil
end
