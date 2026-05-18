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
  live_view: [signing_salt: "rift standalone example"],
  secret_key_base: String.duplicate("a", 64),
  server: false

config :rift_standalone_example, RiftStandaloneExample.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "rift_standalone_example_dev",
  pool_size: 10

config :logger, level: :warning
config :phoenix, :json_library, Jason
config :swoosh, :api_client, false

if File.exists?(Path.join(__DIR__, "#{config_env()}.exs")) do
  import_config "#{config_env()}.exs"
end
