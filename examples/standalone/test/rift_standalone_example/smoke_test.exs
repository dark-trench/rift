defmodule RiftStandaloneExample.SmokeTest do
  use ExUnit.Case, async: false

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias Rift.Cases.Case
  alias Rift.Cases.Event
  alias Rift.Cases
  alias RiftStandaloneExample.CaseTypes.AccessChange
  alias RiftStandaloneExample.CaseTypes.DataExport
  alias RiftStandaloneExample.CaseTypes.VendorOnboarding
  alias RiftStandaloneExample.Repo
  alias RiftStandaloneExample.Resolver

  @endpoint RiftStandaloneExample.Endpoint

  setup do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(Repo, shared: true)
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
  end

  test "serves a host endpoint that uses Rift contracts" do
    conn = get(build_conn(), "/")

    assert html_response(conn, 200) =~ "Rift standalone example"
    assert conn.resp_body =~ "Example Operator"
    assert conn.resp_body =~ "Access change"
  end

  test "mounts Rift through the host router" do
    conn = get(build_conn(), "/rift")

    assert html_response(conn, 200) =~ "Rift"
    assert conn.resp_body =~ ~s(href="/assets/css/app.css")
    assert conn.resp_body =~ ~s(class="rift-mailbox")
    assert conn.resp_body =~ ~s(class="rift-theme-toggle")
    assert conn.resp_body =~ ~s(phx-hook="ThemeToggle")
    assert conn.resp_body =~ ~s(data-phx-theme="system")
    assert conn.resp_body =~ "No open cases"
    refute conn.resp_body =~ "Startable case types"
    assert conn.resp_body =~ "Example Operator"
    assert conn.resp_body =~ "Catalog"
    refute conn.resp_body =~ "Submit request"
    refute conn.resp_body =~ "Access change"
    refute conn.resp_body =~ "Vendor onboarding"
  end

  test "opens and selects case types from the operator catalog" do
    {:ok, view, html} = live(build_conn(), "/rift")

    assert html =~ "No open cases"
    refute html =~ "Startable case types"
    refute html =~ "Access change"

    html =
      view
      |> element("button", "Catalog")
      |> render_click()

    assert html =~ ~s(class="rift-sidebar-list")
    assert html =~ "Access change"
    assert html =~ "Vendor onboarding"
    assert html =~ "Data export"
    assert html =~ "No open cases"
    refute html =~ "Request an operator review before changing access."

    html =
      view
      |> element("button", "Access change")
      |> render_click()

    assert html =~ "Selected case type"
    assert html =~ "Access change"
    assert html =~ "Request an operator review before changing access."
    assert html =~ "admin"
    refute html =~ "Submit request"
    refute html =~ "User"
    refute html =~ "Role"
    refute html =~ "Reason"
  end

  test "filters open cases from the operator inbox search" do
    assert {:ok, _access_case} =
             Cases.open_case(%{
               tenant_key: "example",
               type: "access_change",
               subject: "Access change",
               team: "admin",
               opened_by_ref: "originator-1",
               details: %{"reason" => "Coverage", "role" => "admin"}
             })

    assert {:ok, _vendor_case} =
             Cases.open_case(%{
               tenant_key: "example",
               type: "vendor_onboarding",
               subject: "Vendor onboarding",
               team: "legal",
               opened_by_ref: "originator-2",
               details: %{"vendor_name" => "Northwind"}
             })

    {:ok, view, html} = live(build_conn(), "/rift")

    assert html =~ ~s(name="case_search")
    assert html =~ ~s(placeholder="Subject, team, actor, type, or field value")
    assert html =~ "Access change"
    assert html =~ "Vendor onboarding"

    html =
      view
      |> form(".rift-case-search", case_search: "northwind")
      |> render_change()

    refute html =~ "Access change"
    assert html =~ "Vendor onboarding"
  end

  test "serves host-placed originator case submission routes" do
    conn = get(build_conn(), "/cases/new")

    assert html_response(conn, 200) =~ "New request"
    assert conn.resp_body =~ "Access change"
    assert conn.resp_body =~ "Vendor onboarding"
    assert conn.resp_body =~ "Data export"
    refute conn.resp_body =~ "No open cases"

    {:ok, view, html} = live(build_conn(), "/cases/new/access_change")

    assert html =~ "New request"
    assert html =~ "Access change"
    assert html =~ "Request an operator review before changing access."
    assert html =~ "Submit request"
    assert html =~ "User"
    assert html =~ "Role"
    assert html =~ "Reason"

    html =
      view
      |> form(".rift-originator-form", case_form: %{})
      |> render_submit()

    assert html =~ "can&#39;t be blank"

    html =
      view
      |> form(".rift-originator-form",
        case_form: %{
          "target_user_id" => "user-ada",
          "role" => "admin",
          "reason" => "Coverage"
        }
      )
      |> render_submit()

    assert html =~ "Request submitted"
    refute html =~ "Request ready"
    assert html =~ "Access change"
    refute html =~ "Coverage"

    assert Repo.aggregate(Case, :count) == 1
    assert Repo.aggregate(Event, :count) == 1
    rift_case = Repo.one!(Case)

    conn = get(build_conn(), "/rift")

    assert html_response(conn, 200) =~ "Access change"
    assert conn.resp_body =~ "open"
    assert conn.resp_body =~ "admin"
    assert conn.resp_body =~ ~s(href="/rift/cases/)
    assert conn.resp_body =~ ~s(class="rift-case-link")
    assert conn.resp_body =~ ~s(class="rift-case-time")
    assert conn.resp_body =~ Calendar.strftime(rift_case.inserted_at, "%H:%M")
    refute conn.resp_body =~ "Inbox clear"

    conn = get(build_conn(), "/rift/cases/#{rift_case.id}")

    assert html_response(conn, 200) =~ "Case detail"
    assert conn.resp_body =~ ~s(href="/rift")
    assert conn.resp_body =~ "Back to inbox"
    assert conn.resp_body =~ "hero-arrow-left"
    assert conn.resp_body =~ ~s(class="rift-message")
    assert conn.resp_body =~ ~s(class="rift-message-field")
    assert conn.resp_body =~ ~s(class="rift-message-footer")
    assert conn.resp_body =~ "Rift case"
    assert conn.resp_body =~ "Case summary from the operator inbox."
    refute conn.resp_body =~ "Rift request"
    assert conn.resp_body =~ ~s(class="rift-message-submitted")
    assert conn.resp_body =~ "Submitted"
    assert conn.resp_body =~ Calendar.strftime(rift_case.inserted_at, "%b %d, %Y")
    refute conn.resp_body =~ "access_change submitted"
    assert conn.resp_body =~ ~r/<strong>\s*1\s*<\/strong>/
    refute conn.resp_body =~ "<strong>Open</strong>"
    assert conn.resp_body =~ "Access change"
    assert conn.resp_body =~ "open"
    assert Regex.scan(~r/>open</, conn.resp_body) == [[">open<"]]
    assert conn.resp_body =~ "admin"
    assert conn.resp_body =~ "operator-1"
    assert conn.resp_body =~ "Coverage"
    refute conn.resp_body =~ "Timeline"
    refute conn.resp_body =~ "case_opened"
  end

  test "serves the standalone stylesheet" do
    conn = get(build_conn(), "/assets/css/app.css")

    assert response(conn, 200) =~ ".rift-shell"
    assert conn.resp_body =~ ".rift-mailbox"
    assert conn.resp_body =~ ".rift-case-link"
    assert conn.resp_body =~ ".rift-back-link"
    assert conn.resp_body =~ ".rift-message"
    assert conn.resp_body =~ ".rift-message-field"
    assert conn.resp_body =~ ".rift-message-footer"
    assert conn.resp_body =~ ".rift-case-link:hover {\n  color:"
    refute conn.resp_body =~ ".rift-case-link:hover {\n  background:"
    assert conn.resp_body =~ ~s([data-theme="dark"])
    assert conn.resp_body =~ ".rift-theme-button"
  end

  test "serves Rift javascript for LiveView and theme interactions" do
    conn = get(build_conn(), "/assets/js/app.js")

    assert response(conn, 200) =~ "rift:theme"
    assert conn.resp_body =~ "ThemeToggle"
    assert conn.resp_body =~ "phx:set-theme"
    refute conn.resp_body =~ "Placeholder bundle"
  end

  test "configures Rift to use the host repository" do
    assert Rift.Repo.get() == RiftStandaloneExample.Repo
  end

  test "exposes host-owned resolver and case type data" do
    actor = Resolver.resolve_actor(%Plug.Conn{})

    assert Resolver.resolve_tenant(actor) == "example"
    assert Resolver.resolve_access(actor) == :operator
    assert Resolver.resolve_case_types(actor) == [AccessChange, VendorOnboarding, DataExport]

    assert Resolver.resolve_select_options(actor, AccessChange, :target_user_id) == [
             {"Ada Lovelace", "user-ada"},
             {"Grace Hopper", "user-grace"}
           ]

    assert Resolver.resolve_select_options(actor, VendorOnboarding, :business_owner_id) == [
             {"Katherine Johnson", "user-katherine"},
             {"Dorothy Vaughan", "user-dorothy"}
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
