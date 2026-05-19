defmodule RiftWeb.InboxLive do
  @moduledoc false

  use RiftWeb, :live_view

  alias Rift.CaseCatalog
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
        prefix: Map.fetch!(session, "prefix"),
        resolver: resolver,
        selected_case_entry: nil,
        tenant_key: Map.get(session, "tenant_key")
      )

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def render(assigns), do: index(assigns)

  @impl Phoenix.LiveView
  def handle_event("show_view", %{"view" => view}, socket) do
    socket =
      assign(socket,
        active_view: active_view(view),
        catalog_open?: false,
        selected_case_entry: nil
      )

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

  defp actor_ref(%{id: id}), do: id
  defp actor_ref(actor), do: actor

  defp active_view("catalog"), do: :catalog
  defp active_view(_view), do: :inbox

  defp active_view_label(:catalog), do: "Workflow catalog"
  defp active_view_label(:inbox), do: "Human review queue"

  defp active_view_title(:catalog, nil), do: "Case catalog"
  defp active_view_title(:catalog, entry), do: entry.title
  defp active_view_title(:inbox, _entry), do: "No open cases"

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
end
