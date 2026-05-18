defmodule RiftWeb.PageController do
  use RiftWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
