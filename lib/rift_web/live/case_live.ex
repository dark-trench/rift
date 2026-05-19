defmodule RiftWeb.CaseLive do
  @moduledoc false

  use RiftWeb, :live_view

  alias Rift.CaseCatalog
  alias Rift.Cases
  alias Rift.Resolver

  embed_templates "case_live/*"

  @impl Phoenix.LiveView
  def mount(_params, session, socket) do
    resolver = Map.fetch!(session, "resolver")
    actor = Map.fetch!(session, "actor")
    case_type_entries = CaseCatalog.entries(Map.fetch!(session, "case_types"))

    socket =
      assign(socket,
        access: Map.fetch!(session, "access"),
        actor: actor,
        actor_label:
          Resolver.call_with_fallback(resolver, :resolve_actor_label, [actor_ref(actor)]),
        case_type_entries: case_type_entries,
        detail_entries: [],
        inbox_count: 0,
        prefix: Map.fetch!(session, "prefix"),
        resolver: resolver,
        rift_case: nil,
        tenant_key: Map.get(session, "tenant_key")
      )

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _uri, socket) do
    inbox_count = inbox_count(socket)

    case Cases.fetch_inbox_case(id, %{
           case_types: Enum.map(socket.assigns.case_type_entries, & &1.case_type),
           tenant_key: socket.assigns.tenant_key
         }) do
      {:ok, rift_case} ->
        {:noreply,
         assign(socket,
           detail_entries: sorted_entries(rift_case.details),
           inbox_count: inbox_count,
           rift_case: rift_case
         )}

      {:error, :not_found} ->
        {:noreply,
         assign(socket,
           detail_entries: [],
           inbox_count: inbox_count,
           rift_case: nil
         )}
    end
  end

  @impl Phoenix.LiveView
  def render(assigns), do: detail(assigns)

  defp actor_ref(%{id: id}), do: id
  defp actor_ref(actor), do: actor

  defp inbox_path(prefix), do: prefix

  defp inbox_count(socket) do
    socket.assigns
    |> inbox_scope()
    |> Cases.list_inbox_cases()
    |> length()
  end

  defp inbox_scope(assigns) do
    %{
      case_types: Enum.map(assigns.case_type_entries, & &1.case_type),
      tenant_key: assigns.tenant_key
    }
  end

  defp sorted_entries(value) when value in [nil, %{}], do: []

  defp sorted_entries(value) when is_map(value) do
    value
    |> Enum.map(fn {key, value} -> {key, value} end)
    |> Enum.sort_by(fn {key, _value} -> to_string(key) end)
  end

  defp display_value(value) when is_binary(value), do: value
  defp display_value(value), do: inspect(value)

  defp submitted_at(%DateTime{} = datetime), do: Calendar.strftime(datetime, "%b %d, %Y")
end
