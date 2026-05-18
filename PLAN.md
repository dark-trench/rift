# Rift V1 Plan

## Motivation

Squid Mesh is a strong use case for Jido, but it also needs a strong use case of
its own. Rift is that dogfood app: a real human-operated surface that puts
pressure on the runtime through approvals, rejections, cancellation, ownership,
audit timelines, side effects, stale operator actions, failed side effects, and
runtime inspection.

Rift should be useful on its own, not only as a demo. The goal is to give
Phoenix apps an embeddable ops inbox for work that needs human decisions while
letting the host app keep domain ownership.

Rift owns the human-facing ops surface. Squid Mesh owns durable workflow
execution. SquidSonar owns runtime inspection. The host app owns auth, actors,
tenancy, teams, domain data, selectable values, file storage, side effects, and
workflow modules.

## Product Shape

Rift is an embeddable Phoenix/LiveView package.

V1 provides:

- Case submission from host-defined case types.
- Generated LiveView forms from host-provided field definitions.
- A "My Cases" view for originators.
- An operator action inbox for cases needing human attention.
- Case detail pages with timeline, ownership, comments, attachment references,
  action buttons, and linked runtime state.
- Approve, reject, cancel, claim, release, and assign actions.
- Lifecycle hooks for host-defined side effects.
- SquidSonar link or embed for workflow graph, history, and explanations.

V1 explicitly avoids:

- Generic help desk features.
- No-code workflow building.
- Built-in users, teams, tenants, roles, or auth.
- Built-in file storage.
- Domain-specific case types.
- Visual workflow editing.
- Replay or arbitrary unblock controls.
- Standalone SaaS.

## Core Model

Each Rift case maps to exactly one Squid Mesh workflow run.

```text
Rift Case
  human-facing object:
  who opened it, what it is about, status, owner, comments, attachments, timeline

Squid Mesh Run
  execution object:
  steps, retries, pauses, approval gates, compensation, failures, diagnostics
```

Rift never introspects Squid Mesh workflow modules to build forms. The host app
provides a small case type adapter that describes the human form and maps
submitted data into the workflow payload.

## UI

### Case Submission

Users open `/cases/new` and pick a case type exposed by the host resolver.
Rift renders `/cases/new/:type` from that case type's field definitions.

On submit, Rift:

1. Validates generic field constraints.
2. Creates a case.
3. Appends `case_opened`.
4. Calls the case type payload builder.
5. Starts the configured Squid Mesh workflow and trigger.
6. Stores `squid_mesh_run_id`.
7. Appends `workflow_started`.
8. Runs `after_opened`.
9. Redirects to the case detail page.

### My Cases

`/cases/mine` shows cases opened by the current actor in the current tenant.

The list shows subject, type, status, assignee, last event time, and whether
the case needs attention.

The detail page shows public events, status, submitted data summary, comments,
and visible attachment references.

### Operator Inbox

`/` is the operator landing page. It defaults to cases needing action:

- `waiting_for_approval`
- `failed`
- `side_effect_failed`
- case-type-specific actionable states

Filters:

- status
- type
- team
- assignee
- updated time

The case detail page shows the full event timeline, internal notes, ownership
controls, linked Squid Mesh run status, current waiting reason,
approve/reject/cancel actions, side-effect failures, and a SquidSonar link or
embed.

## Public Interfaces

### Router

```elixir
defmodule MyAppWeb.Router do
  use MyAppWeb, :router
  use Rift.Router

  scope "/ops" do
    pipe_through [:browser, :require_authenticated_user]

    rift "/rift", otp_app: :my_app, resolver: MyApp.RiftResolver
  end
end
```

Routes mounted by Rift:

- `/`
- `/cases/new`
- `/cases/new/:type`
- `/cases/mine`
- `/cases/:id`

### Resolver

The resolver lets the host app provide actor, tenancy, access, available case
types, select options, and display labels.

```elixir
defmodule MyApp.RiftResolver do
  @behaviour Rift.Resolver

  @impl true
  def resolve_actor(conn), do: conn.assigns.current_user

  @impl true
  def resolve_tenant(actor), do: "account:#{actor.account_id}"

  @impl true
  def resolve_access(actor) do
    if actor.operator?, do: :operator, else: :originator
  end

  @impl true
  def resolve_case_types(_actor) do
    [
      MyApp.RiftCases.AccessChange,
      MyApp.RiftCases.DataExport,
      MyApp.RiftCases.ReleaseApproval
    ]
  end

  @impl true
  def resolve_select_options(_actor, MyApp.RiftCases.AccessChange, :target_user_id) do
    MyApp.Accounts.list_users()
    |> Enum.map(&{&1.name, &1.id})
  end

  @impl true
  def resolve_actor_label(actor_ref) do
    MyApp.Accounts.display_name(actor_ref)
  end

  @impl true
  def resolve_attachment_url(attachment_ref) do
    MyApp.Files.signed_url(attachment_ref)
  end
end
```

### Case Type

Case types are code-defined by the host app. They describe the human form,
workflow mapping, payload mapping, allowed actions, and optional side effects.

```elixir
defmodule MyApp.RiftCases.AccessChange do
  use Rift.CaseType

  @impl true
  def type, do: :access_change

  @impl true
  def title, do: "Access change"

  @impl true
  def description, do: "Ask an operator to review a role or permission change."

  @impl true
  def team, do: "admin"

  @impl true
  def fields do
    [
      field(:target_user_id, :select,
        label: "User",
        required: true,
        options: {:resolver, :target_user_id}
      ),
      field(:role, :select,
        label: "Role",
        required: true,
        options: [{"Operator", "operator"}, {"Admin", "admin"}]
      ),
      field(:reason, :textarea,
        label: "Reason",
        required: true
      )
    ]
  end

  @impl true
  def workflow, do: MyApp.Workflows.AccessChange

  @impl true
  def trigger, do: :submit

  @impl true
  def build_payload(attrs, ctx) do
    %{
      target_user_id: attrs.target_user_id,
      role: attrs.role,
      reason: attrs.reason,
      opened_by: ctx.actor.id
    }
  end

  @impl true
  def after_approved(rift_case, ctx) do
    MyApp.Audit.record(:access_change_approved, %{
      case_id: rift_case.id,
      actor_id: ctx.actor.id
    })
  end

  @impl true
  def after_rejected(rift_case, ctx) do
    MyApp.Notifications.notify_case_rejected(rift_case, ctx.actor)
  end

  @impl true
  def after_cancelled(rift_case, ctx) do
    MyApp.Audit.record(:access_change_cancelled, %{
      case_id: rift_case.id,
      actor_id: ctx.actor.id
    })
  end
end
```

The important boundary:

- `fields/0` describes the human form.
- `build_payload/2` maps submitted form data into the Squid Mesh payload.
- Lifecycle hooks run host side effects after Rift accepts an action.
- Rift never derives forms from Squid Mesh workflow modules.

Supported v1 field types:

- `:text`
- `:textarea`
- `:number`
- `:boolean`
- `:date`
- `:select`
- `:multi_select`
- `:hidden`

Select options may be static or resolved by `Rift.Resolver`.

## Tables

Rift should install tables with `mix rift.install`, following the same
host-migration pattern used by Squid Mesh.

### `rift_cases`

Fields:

- `id :binary_id`
- `tenant_key :string`
- `type :string`
- `subject :string`
- `status :string`
- `team :string`
- `opened_by_ref :string`
- `assignee_ref :string`
- `state :map`
- `details :map`
- `squid_mesh_run_id :binary_id`
- timestamps

Indexes:

- `tenant_key`
- `type`
- `status`
- `team`
- `assignee_ref`
- `squid_mesh_run_id`
- `updated_at`

### `rift_case_events`

Fields:

- `id :binary_id`
- `case_id :binary_id`
- `tenant_key :string`
- `actor_ref :string`
- `type :string`
- `data :map`
- `visible_to_originator :boolean`
- timestamps

Indexes:

- `case_id`
- `tenant_key`
- `type`
- `inserted_at`

## Event Types

V1 event types:

- `case_opened`
- `comment_added`
- `attachment_referenced`
- `workflow_started`
- `case_claimed`
- `case_released`
- `case_assigned`
- `case_approved`
- `case_rejected`
- `case_cancelled`
- `side_effect_completed`
- `side_effect_failed`
- `system_note`

## Statuses

V1 statuses:

- `draft`
- `open`
- `running`
- `waiting_for_approval`
- `approved`
- `rejected`
- `cancelled`
- `failed`
- `side_effect_failed`
- `completed`

Status is cached on `rift_cases` for inbox performance and reconciled from
Squid Mesh run inspection on case detail reads.

## Lifecycle Hooks

Host-defined case types may implement:

- `after_opened/2`
- `after_approved/2`
- `after_rejected/2`
- `after_cancelled/2`
- `after_assigned/2`
- `after_released/2`

Hook return values:

- `:ok`
- `{:ok, map()}`
- `{:error, term()}`

Approve, reject, and cancel call Squid Mesh first. Hooks run only after the
runtime action succeeds.

Hook failures do not rollback accepted runtime actions. Rift appends
`side_effect_failed`, marks the case actionable, and shows the failure in the
operator inbox.

## Example Cases

### Access Change

An employee opens an access-change case. The form asks for a target user, role,
and reason. The Squid Mesh workflow pauses for operator approval. If approved,
the workflow applies the access change and Rift records the approval side
effect. If rejected, Rift triggers the host notification hook.

### Data Export

A user opens a data-export case. The host-defined form asks for scope, date
range, and reason. The workflow validates the request, pauses for approval,
generates an export after approval, and records the generated file reference as
an attachment event.

### Release Approval

An operator opens a release-approval case. The form captures release version,
environment, checklist notes, and rollback plan. The workflow waits for review.
Approval continues the release workflow. Cancellation triggers a host hook that
records the cancelled release decision.

## Test Plan

Tests should cover:

- Router mount options, invalid options, session data, and resolver fallback.
- `mix rift.install` creating one current-schema migration and skipping when
  already installed.
- Case opening, generated form validation, event creation, Squid Mesh start
  success, and Squid Mesh start failure.
- Claim, release, assign, approve, reject, cancel, and status reconciliation.
- Lifecycle hook success and failure.
- LiveView type picker, generated submit form, My Cases, action inbox filters,
  detail timeline visibility, ownership controls, side-effect failure display,
  and action button access.
- Minimal host app smoke path with one approval workflow, one rejection hook,
  one cancellation hook, SquidSonar mounted, and the full open -> claim -> wait
  -> approve/reject/cancel -> inspect flow.

Stress scenarios for Squid Mesh:

- Concurrent case openings.
- Duplicate submissions.
- Approval after cancellation.
- Stale detail pages approving an already-terminal run.
- Hook failure after accepted runtime transition.
- Run inspection after restart.

## Open Design Notes

- Rift should prefer boring form primitives in v1. Rich custom fields can come
  later through host-provided render hooks if real usage requires them.
- Rift should expose enough context for host hooks without making host domain
  data part of Rift's schema.
- Rift should avoid becoming a standalone workflow engine. Case state supports
  human UX; Squid Mesh remains the execution source of truth.
- Rift should stay useful even when SquidSonar is not mounted, but the best
  operator experience should include SquidSonar runtime inspection.
