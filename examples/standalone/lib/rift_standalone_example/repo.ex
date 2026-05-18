defmodule RiftStandaloneExample.Repo do
  @moduledoc false

  use Ecto.Repo,
    otp_app: :rift_standalone_example,
    adapter: Ecto.Adapters.Postgres
end
