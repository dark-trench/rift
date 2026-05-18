# Rift Standalone Example

This is a minimal Phoenix host application that depends on Rift by path.

It exists to smoke test Rift as an embeddable package: the host owns the repo,
endpoint, router, actor resolver, and case type definitions.

```sh
mix deps.get
mix test
```
