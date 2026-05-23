defmodule RiftWeb.CaseLiveTest do
  use RiftWeb.LiveCase

  @fake_id Ecto.UUID.generate()

  describe "access boundary" do
    test "mounts for operator even when case is not found", %{conn: conn} do
      {:ok, _view, _html} = live(as_operator(conn), "/rift/cases/#{@fake_id}")
    end

    test "redirects originator to root", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/"}}} =
               live(as_originator(conn), "/rift/cases/#{@fake_id}")
    end

    test "redirects unauthenticated request to root", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/"}}} =
               live(conn, "/rift/cases/#{@fake_id}")
    end
  end
end
