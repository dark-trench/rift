<div align="center">
  <h2>Rift—LiveView ops inbox for human workflow decisions</h2>
  
  <img width="300" alt="rift-logo" src="https://github.com/user-attachments/assets/5ed2212b-e241-4533-b02e-a32fd151bd0f" />

  <p>
    <a href="https://github.com/dark-trench/rift/blob/main/LICENSE">
      <img alt="License: Apache 2.0" src="https://img.shields.io/badge/license-Apache%202.0-blue.svg" />
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

## Development

Rift is a Phoenix 1.8 application.

```sh
mix setup
mix phx.server
```

Before opening a pull request, run:

```sh
mix precommit
```
