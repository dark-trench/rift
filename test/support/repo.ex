defmodule Rift.Test.Repo do
  @moduledoc false

  use Ecto.Repo,
    otp_app: :rift,
    adapter: Ecto.Adapters.Postgres
end
