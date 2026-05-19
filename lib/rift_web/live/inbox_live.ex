defmodule RiftWeb.InboxLive do
  @moduledoc false

  use Phoenix.LiveView

  alias Rift.Resolver

  @impl Phoenix.LiveView
  def mount(_params, session, socket) do
    resolver = Map.fetch!(session, "resolver")
    actor = Map.fetch!(session, "actor")

    socket =
      assign(socket,
        access: Map.fetch!(session, "access"),
        actor_label:
          Resolver.call_with_fallback(resolver, :resolve_actor_label, [actor_ref(actor)]),
        case_types: Map.fetch!(session, "case_types"),
        prefix: Map.fetch!(session, "prefix"),
        tenant_key: Map.get(session, "tenant_key")
      )

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <main class="rift-shell">
      <section>
        <p>Rift</p>
        <h1>Operator inbox</h1>
        <p>Actor: {@actor_label}</p>
        <p :if={@tenant_key}>Tenant: {@tenant_key}</p>
        <p>Access: {@access}</p>
      </section>

      <section>
        <h2>Available case types</h2>
        <ul>
          <li :for={case_type <- @case_types}>
            {case_type.title()}
          </li>
        </ul>
      </section>
    </main>
    """
  end

  defp actor_ref(%{id: id}), do: id
  defp actor_ref(actor), do: actor
end
