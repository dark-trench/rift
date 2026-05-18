ExUnit.start()

{:ok, _pid} = Rift.Repo.get().start_link()
{:ok, _pid} = RiftWeb.Endpoint.start_link()
Ecto.Adapters.SQL.Sandbox.mode(Rift.Repo.get(), :manual)
