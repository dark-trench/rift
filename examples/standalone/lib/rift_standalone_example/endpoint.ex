defmodule RiftStandaloneExample.Endpoint do
  @moduledoc false

  use Phoenix.Endpoint, otp_app: :rift_standalone_example

  socket("/live", Phoenix.LiveView.Socket)

  plug(Plug.Session,
    store: :cookie,
    key: "_rift_standalone_example_key",
    signing_salt: "rift standalone"
  )

  plug(RiftStandaloneExample.Router)
end
