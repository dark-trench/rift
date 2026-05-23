defmodule RiftWeb.InboxLiveTest do
  use RiftWeb.LiveCase

  describe "access boundary" do
    test "mounts for operator", %{conn: conn} do
      {:ok, _view, html} = live(as_operator(conn), "/rift")
      assert html =~ "Operator inbox"
    end

    test "redirects originator to root", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/"}}} = live(as_originator(conn), "/rift")
    end

    test "redirects unauthenticated request to root", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/"}}} = live(conn, "/rift")
    end
  end
end
