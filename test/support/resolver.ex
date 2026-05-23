defmodule Rift.Test.Resolver do
  @moduledoc false

  @behaviour Rift.Resolver

  @impl true
  def resolve_actor(conn) do
    %{
      id: Plug.Conn.get_session(conn, "_test_actor_id") || "test-actor",
      access: Plug.Conn.get_session(conn, "_test_access") || :originator
    }
  end

  @impl true
  def resolve_tenant(_actor), do: "test-tenant"

  @impl true
  def resolve_access(%{access: access}), do: access

  @impl true
  def resolve_case_types(_actor), do: []

  @impl true
  def resolve_actor_label(_ref), do: "Test Actor"

  @impl true
  def resolve_attachment_url(_ref), do: nil
end
