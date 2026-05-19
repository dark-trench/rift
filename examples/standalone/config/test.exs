import Config

config :rift_standalone_example, start_repo?: false

config :rift_standalone_example, RiftStandaloneExample.Endpoint,
  secret_key_base: String.duplicate("a", 64),
  server: false

config :rift_standalone_example, RiftStandaloneExample.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "rift_standalone_example_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2
