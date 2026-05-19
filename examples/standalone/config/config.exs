import Config

config :rift_standalone_example,
  ecto_repos: [RiftStandaloneExample.Repo],
  generators: [timestamp_type: :utc_datetime],
  start_repo?: true

config :rift,
  repo: RiftStandaloneExample.Repo

config :rift_standalone_example, RiftStandaloneExample.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: RiftStandaloneExample.ErrorHTML],
    layout: false
  ],
  pubsub_server: RiftStandaloneExample.PubSub,
  live_view: [signing_salt: "rift standalone example"]

config :logger, level: :warning
config :phoenix, :json_library, Jason
config :swoosh, :api_client, false

import_config "#{config_env()}.exs"
