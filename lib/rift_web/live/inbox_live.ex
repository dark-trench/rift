defmodule RiftWeb.InboxLive do
  @moduledoc false

  use Phoenix.LiveView

  alias Phoenix.LiveView.JS
  alias Rift.CaseCatalog
  alias Rift.Resolver

  @impl Phoenix.LiveView
  def mount(_params, session, socket) do
    resolver = Map.fetch!(session, "resolver")
    actor = Map.fetch!(session, "actor")
    case_types = Map.fetch!(session, "case_types")
    case_type_entries = CaseCatalog.entries(case_types)

    socket =
      assign(socket,
        access: Map.fetch!(session, "access"),
        actor_label:
          Resolver.call_with_fallback(resolver, :resolve_actor_label, [actor_ref(actor)]),
        active_view: :inbox,
        catalog_open?: false,
        case_type_count: length(case_type_entries),
        case_type_entries: case_type_entries,
        prefix: Map.fetch!(session, "prefix"),
        selected_case_entry: nil,
        tenant_key: Map.get(session, "tenant_key")
      )

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <main class="rift-shell">
      <section class="rift-mailbox" aria-label="Rift operator inbox">
        <aside class="rift-sidebar">
          <div class="rift-brand">
            <span class="rift-brand-mark">R</span>
            <div>
              <p>Rift</p>
              <h1>Operator inbox</h1>
            </div>
          </div>

          <div
            id="rift-theme-toggle"
            class="rift-theme-toggle"
            aria-label="Theme"
            phx-hook="ThemeToggle"
          >
            <button
              type="button"
              class="rift-theme-button theme-toggle-btn"
              phx-click={JS.dispatch("phx:set-theme")}
              data-phx-theme="system"
              title="System theme"
            >
              System
            </button>
            <button
              type="button"
              class="rift-theme-button theme-toggle-btn"
              phx-click={JS.dispatch("phx:set-theme")}
              data-phx-theme="light"
              title="Light theme"
            >
              Light
            </button>
            <button
              type="button"
              class="rift-theme-button theme-toggle-btn"
              phx-click={JS.dispatch("phx:set-theme")}
              data-phx-theme="dark"
              title="Dark theme"
            >
              Dark
            </button>
          </div>

          <div class="rift-nav" aria-label="Inbox views">
            <button
              type="button"
              class={nav_item_class(@active_view, :inbox)}
              phx-click="show_view"
              phx-value-view="inbox"
            >
              <span>Inbox</span>
              <strong>0</strong>
            </button>
            <button type="button" class="rift-nav-item" disabled>
              <span>Assigned</span>
              <strong>0</strong>
            </button>
            <button type="button" class="rift-nav-item" disabled>
              <span>Resolved</span>
              <strong>0</strong>
            </button>
            <button
              type="button"
              class={catalog_item_class(@catalog_open?)}
              phx-click="toggle_catalog"
            >
              <span>Catalog</span>
              <strong>{@case_type_count}</strong>
            </button>

            <ul :if={@catalog_open?} class="rift-sidebar-list">
              <li :for={entry <- @case_type_entries}>
                <button
                  type="button"
                  class={sidebar_case_class(@selected_case_entry, entry)}
                  phx-click="select_case_type"
                  phx-value-case-type={entry.key}
                >
                  <span class="rift-case-dot" aria-hidden="true"></span>
                  <span>{entry.title}</span>
                </button>
              </li>
            </ul>
          </div>

          <dl class="rift-context">
            <div>
              <dt>Actor</dt>
              <dd>{@actor_label}</dd>
            </div>
            <div :if={@tenant_key}>
              <dt>Tenant</dt>
              <dd>{@tenant_key}</dd>
            </div>
            <div>
              <dt>Access</dt>
              <dd>{@access}</dd>
            </div>
          </dl>
        </aside>

        <section class="rift-inbox-panel">
          <header class="rift-toolbar">
            <div>
              <p>{active_view_label(@active_view)}</p>
              <h2>{active_view_title(@active_view, @selected_case_entry)}</h2>
            </div>
            <span class="rift-count-pill">{case_type_count_label(@case_type_count)}</span>
          </header>

          <section :if={@active_view == :inbox} class="rift-empty" aria-label="Empty inbox">
            <div>
              <h3>Inbox clear</h3>
              <p>New workflow decisions will land here for review.</p>
            </div>
          </section>

          <section
            :if={@active_view == :catalog}
            class="rift-case-types"
            aria-labelledby="rift-case-types-title"
          >
            <div :if={is_nil(@selected_case_entry)} class="rift-section-heading">
              <p>Catalog</p>
              <h3 id="rift-case-types-title">Select a case type</h3>
              <span>Choose a case type from the sidebar to preview its operator workflow.</span>
            </div>

            <div :if={@selected_case_entry} class="rift-case-detail">
              <div class="rift-section-heading">
                <p>Selected case type</p>
                <h3 id="rift-case-types-title">{@selected_case_entry.title}</h3>
                <span>{@selected_case_entry.description}</span>
              </div>

              <dl>
                <div>
                  <dt>Workflow</dt>
                  <dd>{@selected_case_entry.title}</dd>
                </div>
                <div :if={@selected_case_entry.team}>
                  <dt>Team</dt>
                  <dd>
                    <span class="rift-case-chip">
                      {@selected_case_entry.team}
                    </span>
                  </dd>
                </div>
              </dl>
            </div>
          </section>
        </section>
      </section>
    </main>
    """
  end

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
    socket =
      assign(socket,
        active_view: :catalog,
        catalog_open?: true,
        selected_case_entry: CaseCatalog.select(socket.assigns.case_type_entries, case_type_key)
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
