# Rift Standalone Example

This is a minimal Phoenix host application that depends on Rift by path.

It exists to smoke test Rift as an embeddable package: the host owns the repo,
endpoint, router, actor resolver, and case type definitions.

The example mounts the operator inbox at `/rift` and originator case submission
at `/cases/new`, with originator case tracking at `/cases/mine`. This matches
how a real host can place each surface under a different router scope or
authentication pipeline.

Use this app when developing Rift features that affect routing, LiveView
behavior, styling, generated forms, case state, or workflow-facing behavior. A
feature is easier to trust when it is represented here with a realistic resolver,
case type, workflow module, and smoke test.

```sh
mix deps.get
mix test
```

For manual QA:

```sh
mix ecto.create
mix ecto.migrate
mix phx.server
```

Open `http://localhost:4000`, submit cases through `/cases/new`, review
originator state through `/cases/mine`, and review operator state through
`/rift`.
