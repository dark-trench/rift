# Rift Standalone Example

This is a minimal Phoenix host application that depends on Rift by path.

It exists to smoke test Rift as an embeddable package: the host owns the repo,
endpoint, router, actor resolver, and case type definitions.

The example mounts the operator inbox at `/rift` and originator case submission
at `/cases/new`, matching how a real host can place each surface under a
different router scope or authentication pipeline.

```sh
mix deps.get
mix test
```
