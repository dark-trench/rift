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

## Current Implementation State

Implemented:

- Router macros for operator and originator surfaces:
  - `rift/2` mounts the operator inbox and case detail page.
  - `rift_originator/2` mounts originator submission and My Cases routes.
- Host resolver session data for actor, tenancy, access, case types, and labels.
- Spark-backed `use Rift.CaseType` DSL for host-defined case metadata, fields,
  workflow module, and trigger.
- Generated originator case forms from DSL field definitions.
- Static and resolver-backed select options.
- Case and event persistence through `rift_cases` and `rift_case_events`.
- `mix rift.install` host migration generation for the current case/event schema.
- Case opening that validates form input, builds the host payload, persists the
  case, and appends a public `case_opened` event.
- Operator inbox list, search, and case detail shell.
- Originator My Cases list with status filtering.
- Standalone example app and smoke tests for Rift as an embedded dependency.

Still planned for V1:

- Starting the configured Squid Mesh workflow during case opening and storing
  `squid_mesh_run_id`.
- Workflow start failure handling and retry-safe case state.
- Claim, release, assign, approve, reject, and cancel actions.
- Lifecycle hook execution after accepted runtime actions.
- Runtime status reconciliation from Squid Mesh run inspection.
- Comments, attachment references, event timelines, and internal notes.
- Private read receipts and unread filters.
- SquidSonar link or embed for runtime inspection.
- Stronger explicit authorization scopes and adversarial permission tests.

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
4. Calls the case type payload builder and stores the submitted payload in
   `details`.

The remaining V1 submit path should then:

1. Start the configured Squid Mesh workflow and trigger.
2. Store `squid_mesh_run_id`.
3. Append `workflow_started`.
4. Run `after_opened`.
5. Redirect to the case detail page.

### My Cases

`/cases/mine` shows cases opened by the current actor in the current tenant.

The implemented list shows subject, type, status, assignee, submitted time, and
last updated time, with a status filter. It should eventually show whether the
case has unread activity for the current originator.

Originator case detail is still planned. It should show public events, status,
submitted data summary, comments, and visible attachment references.

### Operator Inbox

`/` is the operator landing page. The implemented inbox currently lists open
cases visible to the operator's tenant and allowed case types, with text search
over case metadata and submitted details.

The V1 inbox should default to cases needing action:

- `waiting_for_approval`
- `failed`
- `side_effect_failed`
- case-type-specific actionable states

Planned filters:

- status
- type
- team
- assignee
- updated time

The implemented case detail page is an operator-facing submitted-data shell. The
V1 detail page should show the full event timeline, internal notes, ownership
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

  scope "/" do
    pipe_through [:browser, :require_authenticated_user]

    rift_originator "/cases", otp_app: :my_app, resolver: MyApp.RiftResolver
  end
end
```

Routes mounted by Rift:

- `rift "/rift"` mounts `/rift` and `/rift/cases/:id`.
- `rift_originator "/cases"` mounts `/cases/new`, `/cases/new/:type`, and
  `/cases/mine`.

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
Metadata and fields are declared with the Rift case type DSL. Payload mapping
and lifecycle side effects remain normal Elixir callbacks.

```elixir
defmodule MyApp.RiftCases.AccessChange do
  use Rift.CaseType

  case_type do
    type :access_change
    title "Access change"
    description "Ask an operator to review a role or permission change."
    team "admin"
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

- `case_type do ... end` declares the stable type, UI copy, queue/team,
  workflow module, trigger, and human form fields.
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

Rift installs its current case and event tables with `mix rift.install`,
following the same host-migration pattern used by Squid Mesh. Read receipts are
planned as a follow-up schema.

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

### `rift_case_reads`

Read state is private per actor and audience. Rift should not infer unread state
from case status, and it should not expose one audience's read state to another
audience. Originators can filter by whether they personally have unread visible
activity. Operators can filter by whether they personally have unread operator
activity.

A case is unread for the current actor when there is a newer event visible to
that actor's audience than their latest read receipt.

Fields:

- `id :binary_id`
- `case_id :binary_id`
- `tenant_key :string`
- `actor_ref :string`
- `audience :string` (`originator` or `operator`)
- `last_read_at :utc_datetime_usec`
- `last_read_event_id :binary_id`
- timestamps

Indexes:

- `case_id`
- `tenant_key`
- `actor_ref`
- `audience`
- unique `case_id, actor_ref, audience`

Originator unread calculations only consider events with
`visible_to_originator = true`. Operator unread calculations consider internal
case events visible to operators. Opening a case detail page should upsert the
current actor's own read receipt after the visible events have been loaded.

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

Implemented test coverage includes:

- Router mount options, invalid options, session data, and resolver fallback.
- `mix rift.install` creating one current-schema migration and skipping when
  already installed.
- Case opening, generated form validation, event creation, case detail scoping,
  originator My Cases scoping, and status filtering.
- Standalone example smoke coverage for type picker, generated submit form,
  operator inbox, operator detail shell, My Cases, host resolver behavior, and
  stylesheet assertions.

Remaining V1 tests should cover:

- Squid Mesh start success and Squid Mesh start failure.
- Claim, release, assign, approve, reject, cancel, and status reconciliation.
- Lifecycle hook success and failure.
- Action inbox filters, detail timeline visibility, ownership controls,
  side-effect failure display, and action button access.
- Read receipts for originator and operator audiences, including private unread
  filters that never disclose whether another actor or audience has read a case.
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
