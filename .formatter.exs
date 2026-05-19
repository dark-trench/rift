rift_locals_without_parens = [
  case_type: 1,
  description: 1,
  field: 2,
  field: 3,
  fields: 1,
  team: 1,
  title: 1,
  trigger: 1,
  type: 1,
  workflow: 1
]

[
  import_deps: [:ecto, :ecto_sql, :phoenix],
  subdirectories: ["priv/*/migrations"],
  plugins: [Phoenix.LiveView.HTMLFormatter],
  locals_without_parens: rift_locals_without_parens,
  export: [
    locals_without_parens: rift_locals_without_parens
  ],
  inputs: [
    "*.{heex,ex,exs}",
    "{config,lib,test}/**/*.{heex,ex,exs}",
    "examples/standalone/*.{heex,ex,exs}",
    "examples/standalone/{config,lib,test}/**/*.{heex,ex,exs}",
    "priv/*/seeds.exs"
  ]
]
