defmodule RiftStandaloneExample.Router do
  @moduledoc false

  use Phoenix.Router, helpers: false
  use Rift.Router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  scope "/", RiftStandaloneExample do
    pipe_through(:browser)

    get("/", PageController, :home)
  end

  scope "/" do
    pipe_through(:browser)

    rift("/rift",
      otp_app: :rift_standalone_example,
      resolver: RiftStandaloneExample.Resolver,
      root_layout: {RiftWeb.Layouts, :root}
    )

    rift_originator("/cases",
      otp_app: :rift_standalone_example,
      resolver: RiftStandaloneExample.Resolver,
      root_layout: {RiftWeb.Layouts, :root}
    )
  end
end
