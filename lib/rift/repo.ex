defmodule Rift.Repo do
  use Ecto.Repo,
    otp_app: :rift,
    adapter: Ecto.Adapters.Postgres
end
