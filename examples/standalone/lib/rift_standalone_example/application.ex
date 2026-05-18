defmodule RiftStandaloneExample.Application do
  @moduledoc false

  use Application

  @impl Application
  def start(_type, _args) do
    children =
      repo_children() ++
        [
          {Phoenix.PubSub, name: RiftStandaloneExample.PubSub},
          RiftStandaloneExample.Endpoint
        ]

    Supervisor.start_link(children,
      strategy: :one_for_one,
      name: RiftStandaloneExample.Supervisor
    )
  end

  defp repo_children do
    if Application.get_env(:rift_standalone_example, :start_repo?, true) do
      [RiftStandaloneExample.Repo]
    else
      []
    end
  end
end
