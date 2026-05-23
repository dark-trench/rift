defmodule Rift.LiveAuth do
  @moduledoc """
  LiveView on_mount hooks for Rift access boundary enforcement.
  """

  import Phoenix.LiveView

  @doc """
  Allows operators through and halts all other access levels with a redirect to root.

  Registered on the operator live_session so every operator LiveView is protected
  without per-module boilerplate.
  """
  def on_mount(:require_operator, _params, %{"access" => :operator}, socket),
    do: {:cont, socket}

  def on_mount(:require_operator, _params, _session, socket),
    do: {:halt, redirect(socket, to: "/")}
end
