Mix.Task.run("ecto.create", ["--quiet"])
Mix.Task.run("ecto.migrate", ["--quiet"])

ExUnit.start()

{:ok, _pid} = RiftStandaloneExample.Repo.start_link()
Ecto.Adapters.SQL.Sandbox.mode(RiftStandaloneExample.Repo, :manual)
