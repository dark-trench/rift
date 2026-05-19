defmodule RiftStandaloneExample.Endpoint do
  @moduledoc false

  use Phoenix.Endpoint, otp_app: :rift_standalone_example

  socket("/live", Phoenix.LiveView.Socket)

  plug(Plug.Static,
    at: "/assets/js",
    from: {:rift, "priv/static/assets/js"},
    gzip: false,
    only: ~w(app.js)
  )

  plug(Plug.Static,
    at: "/",
    from: :rift_standalone_example,
    gzip: false,
    only: ~w(assets favicon.ico robots.txt)
  )

  plug(Plug.Session,
    store: :cookie,
    key: "_rift_standalone_example_key",
    signing_salt: "rift standalone"
  )

  plug(RiftStandaloneExample.Router)
end
