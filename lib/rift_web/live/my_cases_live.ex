defmodule RiftWeb.MyCasesLive do
  @moduledoc false

  use RiftWeb, :live_view

  alias Rift.CaseCatalog
  alias Rift.Cases
  alias Rift.Resolver

  embed_templates "my_cases_live/*"

  @impl Phoenix.LiveView
  def mount(_params, session, socket) do
    resolver = Map.fetch!(session, "resolver")
    actor = Map.fetch!(session, "actor")
    case_type_entries = CaseCatalog.entries(Map.fetch!(session, "case_types"))

    socket =
      assign(socket,
        actor: actor,
        actor_label:
          Resolver.call_with_fallback(resolver, :resolve_actor_label, [actor_ref(actor)]),
        case_status: "all",
        case_type_count: length(case_type_entries),
        case_type_entries: case_type_entries,
        status_filter_open?: false,
        cases: [],
        filtered_cases: [],
        prefix: Map.fetch!(session, "prefix"),
        tenant_key: Map.get(session, "tenant_key")
      )

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(_params, _uri, socket) do
    cases = originator_cases(socket)

    {:noreply,
     assign(socket,
       cases: cases,
       filtered_cases: filter_cases(cases, socket.assigns.case_status)
     )}
  end

  @impl Phoenix.LiveView
  def render(assigns), do: index(assigns)

  @impl Phoenix.LiveView
  def handle_event("toggle_status_filter", _params, socket) do
    {:noreply, assign(socket, status_filter_open?: !socket.assigns.status_filter_open?)}
  end

  def handle_event("filter_cases", %{"status" => status}, socket) do
    status = normalize_status_filter(status, socket.assigns.cases)

    {:noreply,
     assign(socket,
       case_status: status,
       filtered_cases: filter_cases(socket.assigns.cases, status),
       status_filter_open?: false
     )}
  end

  defp originator_cases(socket) do
    Cases.list_originator_cases(%{
      opened_by_ref: actor_ref(socket.assigns.actor),
      tenant_key: socket.assigns.tenant_key
    })
  end

  defp actor_ref(%{id: id}), do: to_string(id)
  defp actor_ref(actor), do: to_string(actor)

  defp new_case_path(prefix), do: "#{prefix}/new"
  defp my_cases_path(prefix), do: "#{prefix}/mine"

  defp case_count_label(1), do: "1 case"
  defp case_count_label(count), do: "#{count} cases"

  defp status_options(cases) do
    statuses =
      cases
      |> Enum.map(& &1.status)
      |> Enum.uniq()
      |> Enum.sort()

    [{"All", "all"} | Enum.map(statuses, &{status_label(&1), &1})]
  end

  defp filter_button_label("all"), do: "All statuses"
  defp filter_button_label(status), do: status_label(status)

  defp filter_option_class(status, status), do: "rift-filter-option rift-filter-option-active"
  defp filter_option_class(_selected_status, _status), do: "rift-filter-option"

  defp filter_cases(cases, "all"), do: cases
  defp filter_cases(cases, status), do: Enum.filter(cases, &(&1.status == status))

  defp normalize_status_filter("all", _cases), do: "all"

  defp normalize_status_filter(status, cases) do
    if Enum.any?(cases, &(&1.status == status)), do: status, else: "all"
  end

  defp status_label(status) do
    status
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp assignee_label(%{assignee_ref: nil}), do: "Unassigned"
  defp assignee_label(%{assignee_ref: assignee_ref}), do: assignee_ref

  defp case_type_label(case_type_entries, rift_case) do
    case Enum.find(case_type_entries, &(&1.slug == rift_case.type)) do
      %{title: title} -> title
      nil -> rift_case.type
    end
  end

  defp case_updated_at(%DateTime{} = datetime), do: Calendar.strftime(datetime, "%b %d, %Y")
end
