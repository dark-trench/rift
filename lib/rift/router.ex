defmodule Rift.Router do
  @moduledoc """
  Router macro for mounting Rift inside a host Phoenix application.
  """

  alias Rift.Resolver

  @doc """
  Imports the `rift/2` route macro into a host router.
  """
  defmacro __using__(_opts) do
    quote do
      import Rift.Router, only: [rift: 2]
    end
  end

  @doc """
  Mounts Rift routes under the given path.

  ## Options

    * `:otp_app` - host OTP application.
    * `:resolver` - module implementing `Rift.Resolver`.
    * `:as` - route helper/live session name, defaults to `:rift`.
  """
  defmacro rift(path, opts) do
    opts =
      if Macro.quoted_literal?(opts) do
        Macro.prewalk(opts, &expand_alias(&1, __CALLER__))
      else
        opts
      end

    quote bind_quoted: [path: path, opts: opts] do
      prefix = Phoenix.Router.scoped_path(__MODULE__, path)

      scope path, alias: false, as: false do
        import Phoenix.LiveView.Router, only: [live: 4, live_session: 3]

        {session_name, session_opts, route_opts} = Rift.Router.__options__(prefix, opts)

        live_session session_name, session_opts do
          live("/", RiftWeb.InboxLive, :index, route_opts)
        end
      end
    end
  end

  @doc false
  @spec __options__(String.t(), keyword()) :: {atom(), keyword(), keyword()}
  def __options__(prefix, opts) when is_binary(prefix) and is_list(opts) do
    validate_required!(opts, :otp_app)
    validate_required!(opts, :resolver)
    Enum.each(opts, &validate_opt!/1)

    otp_app = Keyword.fetch!(opts, :otp_app)
    resolver = Keyword.fetch!(opts, :resolver)
    session_name = Keyword.get(opts, :as, :rift)

    session_opts = [
      session: {__MODULE__, :__session__, [prefix, otp_app, resolver]},
      root_layout: {RiftWeb.Layouts, :root}
    ]

    {session_name, session_opts, as: session_name}
  end

  @doc false
  @spec __session__(Plug.Conn.t(), String.t(), atom(), module()) :: map()
  def __session__(conn, prefix, otp_app, resolver) do
    actor = Resolver.call_with_fallback(resolver, :resolve_actor, [conn])
    tenant_key = Resolver.call_with_fallback(resolver, :resolve_tenant, [actor])

    %{
      "access" => Resolver.call_with_fallback(resolver, :resolve_access, [actor]),
      "actor" => actor,
      "case_types" => Resolver.call_with_fallback(resolver, :resolve_case_types, [actor]),
      "otp_app" => otp_app,
      "prefix" => prefix,
      "resolver" => resolver,
      "tenant_key" => tenant_key
    }
  end

  defp expand_alias({:__aliases__, _metadata, _aliases} = alias_ast, env) do
    Macro.expand(alias_ast, %{env | function: {:rift, 2}})
  end

  defp expand_alias(other, _env), do: other

  defp validate_required!(opts, key) do
    unless Keyword.has_key?(opts, key) do
      raise ArgumentError, "missing required #{inspect(key)} option for Rift router mount"
    end
  end

  defp validate_opt!({:otp_app, otp_app}) do
    unless is_atom(otp_app) and not is_nil(otp_app) do
      raise ArgumentError, "invalid :otp_app, expected an atom, got: #{inspect(otp_app)}"
    end
  end

  defp validate_opt!({:resolver, resolver}) do
    unless is_atom(resolver) and not is_nil(resolver) do
      raise ArgumentError, "invalid :resolver, expected a module, got: #{inspect(resolver)}"
    end
  end

  defp validate_opt!({:as, route_name}) do
    unless is_atom(route_name) and not is_nil(route_name) do
      raise ArgumentError, "invalid :as, expected an atom, got: #{inspect(route_name)}"
    end
  end

  defp validate_opt!(_option), do: :ok
end
