defmodule RiftWeb.LiveCase do
  @moduledoc """
  Test case for LiveView integration tests that exercise Rift's mounted routes.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      @endpoint RiftWeb.Endpoint

      use RiftWeb, :verified_routes

      import Plug.Conn
      import Phoenix.ConnTest
      import Phoenix.LiveViewTest
      import RiftWeb.LiveCase
    end
  end

  setup tags do
    Rift.DataCase.setup_sandbox(tags)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  @doc "Stamps operator access into the conn session for use with Rift.Test.Resolver."
  def as_operator(conn) do
    Plug.Test.init_test_session(conn, %{"_test_access" => :operator})
  end

  @doc "Stamps originator access into the conn session for use with Rift.Test.Resolver."
  def as_originator(conn) do
    Plug.Test.init_test_session(conn, %{"_test_access" => :originator})
  end
end
