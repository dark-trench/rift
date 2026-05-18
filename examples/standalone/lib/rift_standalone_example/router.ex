defmodule RiftStandaloneExample.Router do
  @moduledoc false

  use Phoenix.Router, helpers: false

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
end
