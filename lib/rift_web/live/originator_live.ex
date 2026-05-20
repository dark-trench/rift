defmodule RiftWeb.OriginatorLive do
  @moduledoc false

  use RiftWeb, :live_view

  alias Rift.CaseCatalog
  alias Rift.CaseForm
  alias Rift.Cases
  alias Rift.Resolver

  embed_templates "originator_live/*"

  @impl Phoenix.LiveView
  def mount(_params, session, socket) do
    resolver = Map.fetch!(session, "resolver")
    actor = Map.fetch!(session, "actor")
    case_types = Map.fetch!(session, "case_types")
    case_type_entries = CaseCatalog.entries(case_types)

    socket =
      assign(socket,
        actor: actor,
        actor_label:
          Resolver.call_with_fallback(resolver, :resolve_actor_label, [actor_ref(actor)]),
        case_type_count: length(case_type_entries),
        case_type_entries: case_type_entries,
        originator_case_count: 0,
        prefix: Map.fetch!(session, "prefix"),
        resolver: resolver,
        selected_case_entry: nil,
        selected_case_form: nil,
        tenant_key: Map.get(session, "tenant_key")
      )

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _uri, socket) do
    selected_case_entry = select_case_type(socket.assigns.case_type_entries, params)

    socket =
      socket
      |> assign(
        selected_case_entry: selected_case_entry,
        selected_case_form:
          case_form(selected_case_entry, socket.assigns.resolver, socket.assigns.actor)
      )
      |> assign_originator_case_count()

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def render(assigns), do: new(assigns)

  @impl Phoenix.LiveView
  def handle_event(
        "validate_case_form",
        %{"case_form" => _params},
        %{assigns: %{selected_case_form: nil}} = socket
      ) do
    {:noreply, socket}
  end

  def handle_event("validate_case_form", %{"case_form" => params}, socket) do
    {:noreply,
     assign(socket,
       selected_case_form: CaseForm.validate(socket.assigns.selected_case_form, params)
     )}
  end

  def handle_event(
        "submit_case_form",
        %{"case_form" => _params},
        %{assigns: %{selected_case_form: nil}} = socket
      ) do
    {:noreply, socket}
  end

  def handle_event("submit_case_form", %{"case_form" => params}, socket) do
    ctx = %{actor: socket.assigns.actor, tenant_key: socket.assigns.tenant_key}

    case Cases.open_case(
           socket.assigns.selected_case_entry.case_type,
           params,
           ctx,
           socket.assigns.resolver
         ) do
      {:ok, _rift_case} ->
        form = %{
          case_form(
            socket.assigns.selected_case_entry,
            socket.assigns.resolver,
            socket.assigns.actor
          )
          | submitted?: true
        }

        {:noreply,
         socket
         |> assign(selected_case_form: form)
         |> assign_originator_case_count()}

      {:error, form} ->
        {:noreply, assign(socket, selected_case_form: form)}
    end
  end

  defp select_case_type(entries, %{"type" => type}), do: CaseCatalog.select_slug(entries, type)
  defp select_case_type(_entries, _params), do: nil

  defp actor_ref(%{id: id}), do: to_string(id)
  defp actor_ref(actor), do: to_string(actor)

  defp new_case_path(prefix), do: "#{prefix}/new"
  defp new_case_path(prefix, entry), do: "#{prefix}/new/#{entry.slug}"
  defp my_cases_path(prefix), do: "#{prefix}/mine"

  defp assign_originator_case_count(socket) do
    count =
      socket
      |> originator_cases_scope()
      |> Cases.list_originator_cases()
      |> length()

    assign(socket, originator_case_count: count)
  end

  defp originator_cases_scope(socket) do
    %{
      opened_by_ref: actor_ref(socket.assigns.actor),
      tenant_key: socket.assigns.tenant_key
    }
  end

  defp new_request_class(nil), do: "rift-nav-item rift-nav-item-active"
  defp new_request_class(_entry), do: "rift-nav-item"

  defp sidebar_case_class(selected_entry, entry) when selected_entry == entry do
    "rift-sidebar-case rift-sidebar-case-active"
  end

  defp sidebar_case_class(_selected_entry, _entry), do: "rift-sidebar-case"

  defp originator_title(nil), do: "New request"
  defp originator_title(entry), do: entry.title

  defp case_type_count_label(1), do: "1 type"
  defp case_type_count_label(count), do: "#{count} types"

  defp case_form(nil, _resolver, _actor), do: nil
  defp case_form(entry, resolver, actor), do: CaseForm.new(entry.case_type, resolver, actor)

  defp field_value(form, field), do: Map.get(form.params, field.input_name, field.value)

  defp input_type(:number), do: "number"
  defp input_type(:boolean), do: "checkbox"
  defp input_type(:date), do: "date"
  defp input_type(:hidden), do: "hidden"
  defp input_type(_type), do: "text"
end
