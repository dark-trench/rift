<div align="center">
  <h2>Rift—LiveView ops inbox for human workflow decisions</h2>
  
  <img width="300" alt="rift-logo" src="https://github.com/user-attachments/assets/5ed2212b-e241-4533-b02e-a32fd151bd0f" />

  <p>
    <a href="https://github.com/dark-trench/rift/actions/workflows/ci.yml">
      <img alt="CI" src="https://img.shields.io/github/actions/workflow/status/dark-trench/rift/ci.yml?branch=main&label=ci" />
    </a>
    <img alt="Elixir 1.18+" src="https://img.shields.io/badge/elixir-1.18%2B-4B275F" />
    <img alt="Phoenix 1.8+" src="https://img.shields.io/badge/phoenix-1.8%2B-FD4F00" />
    <a href="https://github.com/dark-trench/rift/blob/main/LICENSE">
      <img alt="License: Apache 2.0" src="https://img.shields.io/badge/license-Apache--2.0-blue" />
    </a>
  </p>
</div>

Rift gives Phoenix apps a configurable LiveView ops inbox for workflows that
need human decisions.

The host app defines case types in code. Users open cases through host-defined
forms. Each case starts one Squid Mesh workflow run. Operators review cases in
Rift, claim or assign ownership, approve/reject/cancel work, and inspect runtime
details through SquidSonar.

Read the planning document:

- [PLAN.md](PLAN.md)

## Embedding

Rift is built as an embeddable Phoenix package. The host app owns its Ecto repo,
auth, actors, tenancy, case types, workflow modules, selectable values, file
storage, and side effects.

Configure the host repo:

```elixir
config :rift, repo: MyApp.Repo
```

Define host case types with `use Rift.CaseType` and expose host-owned context
through a `Rift.Resolver` implementation.

```elixir
defmodule MyApp.CaseTypes.AccessChange do
  use Rift.CaseType

  case_type do
    type :access_change
    title "Access change"
    description "Ask an operator to review an access change before it runs."
    team "identity"
    workflow MyApp.Workflows.AccessChange
    trigger :submit

    fields do
      field :target_user_id, :select,
        label: "User",
        required: true,
        options: {:resolver, :target_user_id}

      field :role, :select,
        label: "Role",
        required: true,
        options: [{"Operator", "operator"}, {"Admin", "admin"}]

      field :reason, :textarea,
        label: "Reason",
        required: true
    end
  end

  @impl true
  def build_payload(attrs, ctx) do
    %{
      target_user_id: attrs.target_user_id,
      role: attrs.role,
      reason: attrs.reason,
      opened_by: ctx.actor.id
    }
  end
end
```

Mount Rift in the host router:

```elixir
defmodule MyAppWeb.Router do
  use Phoenix.Router
  use Rift.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/" do
    pipe_through :browser

    rift "/rift", otp_app: :my_app, resolver: MyApp.RiftResolver
  end

  scope "/" do
    pipe_through [:browser, :require_authenticated_user]

    rift_originator "/cases", otp_app: :my_app, resolver: MyApp.RiftResolver
  end
end
```

`rift/2` mounts the operator inbox. `rift_originator/2` mounts case submission
routes at `/new` and `/new/:type` under the path you choose, so the host can put
originator intake behind a different auth pipeline, a public signed-token plug,
or any other boundary it owns.

Resolve host-owned actors, tenancy, access, case types, and select options:

```elixir
defmodule MyApp.RiftResolver do
  @behaviour Rift.Resolver

  @impl true
  def resolve_actor(conn), do: conn.assigns.current_user

  @impl true
  def resolve_tenant(actor), do: actor.organization_id

  @impl true
  def resolve_access(_actor), do: :operator

  @impl true
  def resolve_case_types(_actor), do: [MyApp.CaseTypes.AccessChange]

  @impl true
  def resolve_select_options(_actor, MyApp.CaseTypes.AccessChange, :target_user_id) do
    Enum.map(MyApp.Accounts.list_users(), &{&1.name, &1.id})
  end
end
```

Keep the Rift DSL formatted without parentheses by importing Rift in the host
formatter config:

```elixir
[
  import_deps: [:rift],
  inputs: ["{config,lib,test}/**/*.{ex,exs}"]
]
```

## Development

Rift uses Phoenix and LiveView internally, but it should be mounted inside a
host Phoenix application rather than operated as a standalone app.

```sh
mix setup
```

Before opening a pull request, run:

```sh
mix precommit
```

To smoke test Rift as a dependency mounted inside a host app, run:

```sh
mix example.smoke
```
