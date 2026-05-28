defmodule RiftWeb.Router do
  use RiftWeb, :router
  use Rift.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {RiftWeb.Layouts, :root}
    plug :protect_from_forgery

    plug :put_secure_browser_headers, %{
      "content-security-policy" =>
        "default-src 'self'; " <>
          "base-uri 'self'; " <>
          "connect-src 'self'; " <>
          "font-src 'self' data:; " <>
          "form-action 'self'; " <>
          "frame-ancestors 'self'; " <>
          "img-src 'self' data:; " <>
          "script-src 'self'; " <>
          "style-src 'self' 'unsafe-inline'"
    }
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", RiftWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  # Other scopes may use custom stacks.
  # scope "/api", RiftWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:rift, :test_routes, false) do
    scope "/" do
      pipe_through :browser

      rift("/rift",
        otp_app: :rift,
        resolver: Rift.Test.Resolver,
        root_layout: {RiftWeb.Layouts, :root}
      )

      rift_originator("/cases",
        otp_app: :rift,
        resolver: Rift.Test.Resolver,
        root_layout: {RiftWeb.Layouts, :root}
      )
    end
  end

  if Application.compile_env(:rift, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: RiftWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
