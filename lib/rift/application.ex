defmodule Rift.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl Application
  def start(_type, _args) do
    children = [
      RiftWeb.Telemetry,
      Rift.Repo,
      {DNSCluster, query: Application.get_env(:rift, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Rift.PubSub},
      # Start a worker by calling: Rift.Worker.start_link(arg)
      # {Rift.Worker, arg},
      # Start to serve requests, typically the last entry
      RiftWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Rift.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl Application
  def config_change(changed, _new, removed) do
    RiftWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
