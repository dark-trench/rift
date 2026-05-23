defmodule RiftWeb.MyCasesLiveTest do
  use RiftWeb.LiveCase

  describe "access boundary" do
    test "mounts for originator", %{conn: conn} do
      {:ok, _view, html} = live(as_originator(conn), "/cases/mine")
      assert html =~ "My cases"
    end

    test "mounts for operator (operators may also view their own cases)", %{conn: conn} do
      {:ok, _view, html} = live(as_operator(conn), "/cases/mine")
      assert html =~ "My cases"
    end

    test "mounts for unauthenticated request (resolver defaults to originator access)", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/cases/mine")
      assert html =~ "My cases"
    end
  end
end
