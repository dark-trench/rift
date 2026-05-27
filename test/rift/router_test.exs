defmodule Rift.RouterTest do
  use ExUnit.Case, async: true

  defmodule AccessChange do
    use Rift.CaseType

    @impl true
    def type, do: :access_change

    @impl true
    def title, do: "Access change"

    @impl true
    def fields, do: []

    @impl true
    def workflow, do: Rift.RouterTest.AccessChangeWorkflow

    @impl true
    def trigger, do: :submit

    @impl true
    def build_payload(_attrs, _ctx), do: %{}
  end

  defmodule AccessChangeWorkflow do
  end

  defmodule TestResolver do
    @behaviour Rift.Resolver

    @impl true
    def resolve_actor(_conn), do: %{id: "operator-1"}

    @impl true
    def resolve_tenant(_actor), do: "tenant-1"

    @impl true
    def resolve_access(_actor), do: :operator

    @impl true
    def resolve_case_types(_actor), do: [AccessChange]
  end

  defmodule TestRouter do
    use Phoenix.Router, helpers: false
    use Rift.Router

    scope "/" do
      rift("/rift", otp_app: :rift, resolver: TestResolver)
      rift_originator("/cases", otp_app: :rift, resolver: TestResolver)
    end
  end

  test "rift macro mounts the operator landing route" do
    assert Enum.any?(TestRouter.__routes__(), fn route ->
             route.path == "/rift" &&
               elem(get_in(route.metadata, [:phoenix_live_view]), 0) == RiftWeb.InboxLive
           end)
  end

  test "rift macro mounts the operator case detail route" do
    assert Enum.any?(TestRouter.__routes__(), fn route ->
             route.path == "/rift/cases/:id" &&
               elem(get_in(route.metadata, [:phoenix_live_view]), 0) == RiftWeb.CaseLive
           end)
  end

  test "rift_originator macro mounts host-placed case submission routes" do
    assert Enum.any?(TestRouter.__routes__(), fn route ->
             route.path == "/cases/mine" &&
               elem(get_in(route.metadata, [:phoenix_live_view]), 0) == RiftWeb.MyCasesLive
           end)

    assert Enum.any?(TestRouter.__routes__(), fn route ->
             route.path == "/cases/new" &&
               elem(get_in(route.metadata, [:phoenix_live_view]), 0) == RiftWeb.OriginatorLive
           end)

    assert Enum.any?(TestRouter.__routes__(), fn route ->
             route.path == "/cases/new/:type" &&
               elem(get_in(route.metadata, [:phoenix_live_view]), 0) == RiftWeb.OriginatorLive
           end)
  end

  test "__options__/2 builds a live session backed by host options" do
    {session_name, session_opts, route_opts} =
      Rift.Router.__options__("/ops/rift",
        otp_app: :rift,
        resolver: TestResolver,
        root_layout: {RiftWeb.Layouts, :root}
      )

    assert session_name == :rift
    assert route_opts == [as: :rift]

    assert session_opts[:on_mount] == [{Rift.LiveAuth, :require_operator}]

    assert session_opts[:session] ==
             {Rift.Router, :__session__, ["/ops/rift", :rift, TestResolver]}

    assert session_opts[:root_layout] == {RiftWeb.Layouts, :root}
  end

  test "__options__/2 does not set root_layout when not given" do
    {_name, session_opts, _route_opts} =
      Rift.Router.__options__("/ops/rift", otp_app: :rift, resolver: TestResolver)

    refute Keyword.has_key?(session_opts, :root_layout)
  end

  test "__options__/3 does not add on_mount to the originator surface" do
    {_name, session_opts, _route_opts} =
      Rift.Router.__options__(
        "/cases",
        [otp_app: :rift, resolver: TestResolver],
        :rift_originator
      )

    refute Keyword.has_key?(session_opts, :on_mount)
  end

  test "__session__/4 resolves host context through the configured resolver" do
    conn = %Plug.Conn{}

    assert Rift.Router.__session__(conn, "/ops/rift", :rift, TestResolver) == %{
             "access" => :operator,
             "actor" => %{id: "operator-1"},
             "case_types" => [AccessChange],
             "otp_app" => :rift,
             "prefix" => "/ops/rift",
             "resolver" => TestResolver,
             "tenant_key" => "tenant-1"
           }
  end

  test "__options__/2 requires an otp app" do
    assert_raise ArgumentError, ~r/missing required :otp_app/, fn ->
      Rift.Router.__options__("/rift", resolver: TestResolver)
    end
  end

  test "__options__/2 requires a resolver module" do
    assert_raise ArgumentError, ~r/missing required :resolver/, fn ->
      Rift.Router.__options__("/rift", otp_app: :rift)
    end
  end
end
