defmodule RiftWeb.OriginatorLiveTest do
  use RiftWeb.LiveCase

  describe "access boundary" do
    test "mounts for originator", %{conn: conn} do
      {:ok, _view, html} = live(as_originator(conn), "/cases/new")
      assert html =~ "New request"
    end

    test "mounts for operator (operators may also submit requests)", %{conn: conn} do
      {:ok, _view, html} = live(as_operator(conn), "/cases/new")
      assert html =~ "New request"
    end

    test "mounts for unauthenticated request (resolver defaults to originator access)", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/cases/new")
      assert html =~ "New request"
    end
  end
end
