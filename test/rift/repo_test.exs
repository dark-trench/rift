defmodule Rift.RepoTest do
  use ExUnit.Case, async: false

  test "returns the host configured repository" do
    Application.put_env(:rift, :repo, Rift.Test.Repo)

    assert Rift.Repo.get() == Rift.Test.Repo
  end

  test "raises with host configuration guidance when no repository is configured" do
    original = Application.get_env(:rift, :repo)
    Application.delete_env(:rift, :repo)

    on_exit(fn ->
      if original do
        Application.put_env(:rift, :repo, original)
      end
    end)

    assert_raise RuntimeError, ~r/config :rift, repo: YourApp.Repo/, fn ->
      Rift.Repo.get()
    end
  end
end
