defmodule RiftStandaloneExample.SmokeTest do
  use ExUnit.Case, async: true

  import Phoenix.ConnTest

  alias RiftStandaloneExample.CaseTypes.AccessChange
  alias RiftStandaloneExample.Resolver

  @endpoint RiftStandaloneExample.Endpoint

  test "serves a host endpoint that uses Rift contracts" do
    conn = get(build_conn(), "/")

    assert html_response(conn, 200) =~ "Rift standalone example"
    assert conn.resp_body =~ "Example Operator"
    assert conn.resp_body =~ "Access change"
  end

  test "mounts Rift through the host router" do
    conn = get(build_conn(), "/rift")

    assert html_response(conn, 200) =~ "Rift"
    assert conn.resp_body =~ "Example Operator"
    assert conn.resp_body =~ "Access change"
  end

  test "configures Rift to use the host repository" do
    assert Rift.Repo.get() == RiftStandaloneExample.Repo
  end

  test "exposes host-owned resolver and case type data" do
    actor = Resolver.resolve_actor(%Plug.Conn{})

    assert Resolver.resolve_tenant(actor) == "example"
    assert Resolver.resolve_access(actor) == :operator
    assert Resolver.resolve_case_types(actor) == [AccessChange]

    assert Resolver.resolve_select_options(actor, AccessChange, :target_user_id) == [
             {"Ada Lovelace", "user-ada"},
             {"Grace Hopper", "user-grace"}
           ]
  end

  test "builds a workflow payload from host-owned case type data" do
    attrs = %{target_user_id: "user-ada", role: "admin", reason: "Coverage"}
    ctx = %{actor: %{id: "operator-1"}}

    assert AccessChange.build_payload(attrs, ctx) == %{
             target_user_id: "user-ada",
             role: "admin",
             reason: "Coverage",
             opened_by: "operator-1"
           }
  end
end
