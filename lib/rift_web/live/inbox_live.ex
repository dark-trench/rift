defmodule RiftWeb.InboxLive do
  @moduledoc false

  use RiftWeb, :live_view

  alias Rift.CaseCatalog
  alias Rift.Cases
  alias Rift.Resolver

  embed_templates "inbox_live/*"

  @impl Phoenix.LiveView
  def mount(_params, session, socket) do
    resolver = Map.fetch!(session, "resolver")
    actor = Map.fetch!(session, "actor")
    case_types = Map.fetch!(session, "case_types")
    case_type_entries = CaseCatalog.entries(case_types)

    socket =
      assign(socket,
        access: Map.fetch!(session, "access"),
        actor: actor,
        actor_label:
          Resolver.call_with_fallback(resolver, :resolve_actor_label, [actor_ref(actor)]),
        active_view: :inbox,
        catalog_open?: false,
        case_type_count: length(case_type_entries),
        case_type_entries: case_type_entries,
        case_search: "",
        filtered_inbox_cases: [],
        inbox_cases: [],
        inbox_count: 0,
        prefix: Map.fetch!(session, "prefix"),
        resolver: resolver,
        selected_case_entry: nil,
        tenant_key: Map.get(session, "tenant_key")
      )

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(_params, _uri, socket) do
    {:noreply, assign_inbox_cases(socket)}
  end

  @impl Phoenix.LiveView
  def render(assigns), do: index(assigns)

  @impl Phoenix.LiveView
  def handle_event("show_view", %{"view" => view}, socket) do
    socket =
      socket
      |> assign(
        active_view: active_view(view),
        catalog_open?: false,
        selected_case_entry: nil
      )
      |> maybe_assign_inbox_cases()

    {:noreply, socket}
  end

  def handle_event("toggle_catalog", _params, socket) do
    {:noreply, assign(socket, catalog_open?: !socket.assigns.catalog_open?)}
  end

  def handle_event("select_case_type", %{"case-type" => case_type_key}, socket) do
    selected_case_entry = CaseCatalog.select(socket.assigns.case_type_entries, case_type_key)

    socket =
      assign(socket,
        active_view: :catalog,
        catalog_open?: true,
        selected_case_entry: selected_case_entry
      )

    {:noreply, socket}
  end

  def handle_event("search_cases", %{"case_search" => search}, socket) do
    search = String.trim(search)

    socket =
      assign(socket,
        case_search: search,
        filtered_inbox_cases: filter_inbox_cases(socket.assigns.inbox_cases, search)
      )

    {:noreply, socket}
  end

  defp actor_ref(%{id: id}), do: id
  defp actor_ref(actor), do: actor

  defp case_path(prefix, rift_case), do: "#{prefix}/cases/#{rift_case.id}"
  defp case_time(%DateTime{} = datetime), do: Calendar.strftime(datetime, "%H:%M")

  defp filter_inbox_cases(inbox_cases, ""), do: inbox_cases

  defp filter_inbox_cases(inbox_cases, search) do
    query = String.downcase(search)

    Enum.filter(inbox_cases, fn rift_case ->
      rift_case
      |> case_search_text()
      |> String.contains?(query)
    end)
  end

  defp case_search_text(rift_case) do
    search_fragments = [
      rift_case.subject,
      rift_case.status,
      rift_case.team,
      rift_case.opened_by_ref,
      rift_case.type
    ]

    (search_fragments ++ detail_search_fragments(rift_case.details))
    |> Enum.map_join(" ", &to_search_text/1)
    |> String.downcase()
  end

  defp detail_search_fragments(details) when is_map(details) do
    Enum.flat_map(details, fn {key, value} -> [key | detail_search_fragments(value)] end)
  end

  defp detail_search_fragments(values) when is_list(values) do
    Enum.flat_map(values, &detail_search_fragments/1)
  end

  defp detail_search_fragments(nil), do: []
  defp detail_search_fragments(value), do: [value]

  defp to_search_text(nil), do: ""
  defp to_search_text(value) when is_binary(value), do: value
  defp to_search_text(value), do: to_string(value)

  defp assign_inbox_cases(socket) do
    inbox_cases =
      Cases.list_inbox_cases(%{
        case_types: Enum.map(socket.assigns.case_type_entries, & &1.case_type),
        tenant_key: socket.assigns.tenant_key
      })

    assign(socket,
      filtered_inbox_cases: filter_inbox_cases(inbox_cases, socket.assigns.case_search),
      inbox_cases: inbox_cases,
      inbox_count: length(inbox_cases)
    )
  end

  defp maybe_assign_inbox_cases(%{assigns: %{active_view: :inbox}} = socket),
    do: assign_inbox_cases(socket)

  defp maybe_assign_inbox_cases(socket), do: socket

  defp active_view("catalog"), do: :catalog
  defp active_view(_view), do: :inbox

  defp active_view_label(:catalog), do: "Workflow catalog"
  defp active_view_label(:inbox), do: "Human review queue"

  defp active_view_title(:catalog, nil, _inbox_count), do: "Case catalog"
  defp active_view_title(:catalog, entry, _inbox_count), do: entry.title
  defp active_view_title(:inbox, _entry, 0), do: "No open cases"
  defp active_view_title(:inbox, _entry, _inbox_count), do: "Operator inbox"

  defp nav_item_class(active_view, active_view), do: "rift-nav-item rift-nav-item-active"
  defp nav_item_class(_active_view, _view), do: "rift-nav-item"

  defp catalog_item_class(true), do: "rift-nav-item rift-nav-item-expanded"
  defp catalog_item_class(false), do: "rift-nav-item"

  defp sidebar_case_class(selected_entry, entry) when selected_entry == entry do
    "rift-sidebar-case rift-sidebar-case-active"
  end

  defp sidebar_case_class(_selected_entry, _entry), do: "rift-sidebar-case"

  defp case_type_count_label(1), do: "1 type"
  defp case_type_count_label(count), do: "#{count} types"

  defp inbox_count_label(1), do: "1 case"
  defp inbox_count_label(count), do: "#{count} cases"
end
