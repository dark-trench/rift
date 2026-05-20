# Contributing

Rift is an embeddable Phoenix/LiveView package. Develop and QA it as a package
mounted inside a host Phoenix app, not only as isolated library code.

## Setup

```sh
mix setup
```

## Feature Development

Use `examples/standalone` as the contributor development harness for new
features. Every user-facing workflow should be proven in a real host Phoenix
app before review.

When adding a feature:

1. Add or update the core package behavior in `lib/` and focused tests in
   `test/`.
2. Wire a representative version into `examples/standalone` through its router,
   resolver, case types, workflows, templates, or static assets.
3. Add or update standalone smoke coverage in
   `examples/standalone/test/rift_standalone_example/smoke_test.exs`.
4. Use the standalone app for manual QA when the change affects routing,
   LiveView behavior, styling, generated forms, case state, permissions,
   workflow-facing behavior, or host integration boundaries.

## Automated QA

Run the package checks:

```sh
mix precommit
```

Run the standalone host-app smoke suite:

```sh
mix example.smoke
```

## Manual QA

Start the standalone host app:

```sh
cd examples/standalone
mix deps.get
mix ecto.create
mix ecto.migrate
mix phx.server
```

Open `http://localhost:4000`, use `/cases/new` as the originator submission
surface, `/cases/mine` as the originator case-tracking surface, and `/rift` as
the operator surface.

## Pull Requests

Before opening a pull request, confirm the feature is represented in the
standalone example when it affects a user-facing or host-facing workflow.

Keep PRs small, focused, and reviewable in one sitting.
