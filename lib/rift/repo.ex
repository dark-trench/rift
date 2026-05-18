defmodule Rift.Repo do
  @moduledoc """
  Accesses the host application's configured Ecto repository.

  Rift is embedded in another Phoenix app, so database ownership stays with the
  host application. Configure the repo with:

      config :rift, repo: YourApp.Repo
  """

  @doc """
  Returns the host Ecto repository configured for Rift.
  """
  @spec get() :: module()
  def get do
    Application.get_env(:rift, :repo) ||
      raise """
      Rift repo not configured.

      Add to your host application config:

          config :rift, repo: YourApp.Repo
      """
  end
end
