defmodule Rift.Resolver do
  @moduledoc """
  Host application callbacks for actor, tenancy, access, and display data.

  Rift owns the human-facing ops surface, while the host application owns
  authentication, actors, tenants, labels, selectable values, and attachment
  storage. Resolver callbacks make those host-owned values available at the
  embed boundary.
  """

  @type access :: :operator | :originator
  @type case_type :: module()

  @doc "Returns the current host actor from the connection."
  @callback resolve_actor(conn :: Plug.Conn.t()) :: term()

  @doc "Returns the tenant key Rift should use for the actor."
  @callback resolve_tenant(actor :: term()) :: String.t() | nil

  @doc "Returns the actor's Rift access level."
  @callback resolve_access(actor :: term()) :: access()

  @doc "Returns the case types available to the actor."
  @callback resolve_case_types(actor :: term()) :: [case_type()]

  @doc "Returns host-owned options for a resolver-backed field."
  @callback resolve_select_options(actor :: term(), case_type(), field_name :: atom()) :: list()

  @doc "Returns a human display label for a stored actor reference."
  @callback resolve_actor_label(actor_ref :: term()) :: String.t()

  @doc "Returns a URL for a stored attachment reference, or nil when unavailable."
  @callback resolve_attachment_url(attachment_ref :: term()) :: String.t() | nil

  @optional_callbacks resolve_actor: 1,
                      resolve_tenant: 1,
                      resolve_access: 1,
                      resolve_case_types: 1,
                      resolve_select_options: 3,
                      resolve_actor_label: 1,
                      resolve_attachment_url: 1

  @doc """
  Calls a host resolver callback or falls back to Rift's default behavior.
  """
  @spec call_with_fallback(module(), atom(), list()) :: term()
  def call_with_fallback(resolver, callback, args) when is_atom(callback) and is_list(args) do
    if function_exported?(resolver, callback, length(args)) do
      apply(resolver, callback, args)
    else
      apply(__MODULE__, callback, args)
    end
  end

  @doc """
  Default actor resolver.

  Host applications should usually override this to return the current user or
  service actor from the connection.
  """
  @spec resolve_actor(Plug.Conn.t()) :: nil
  def resolve_actor(_conn), do: nil

  @doc """
  Default tenant resolver.

  Returning `nil` keeps tenancy unset for hosts that do not use tenant-scoped
  Rift cases.
  """
  @spec resolve_tenant(term()) :: nil
  def resolve_tenant(_actor), do: nil

  @doc """
  Default access resolver.

  Hosts must return `:operator` for actors allowed to work the operator inbox.
  """
  @spec resolve_access(term()) :: :originator
  def resolve_access(_actor), do: :originator

  @doc """
  Default case-type resolver.

  Hosts expose their selectable case types by overriding this callback.
  """
  @spec resolve_case_types(term()) :: []
  def resolve_case_types(_actor), do: []

  @doc """
  Default select-option resolver.

  Hosts override this when a case field declares resolver-backed options.
  """
  @spec resolve_select_options(term(), case_type(), atom()) :: []
  def resolve_select_options(_actor, _case_type, _field_name), do: []

  @doc """
  Default actor label resolver.

  The fallback is only a display-safe string version of the stored actor
  reference; host apps should override it for human names.
  """
  @spec resolve_actor_label(term()) :: String.t()
  def resolve_actor_label(actor_ref), do: to_string(actor_ref)

  @doc """
  Default attachment URL resolver.

  Returning `nil` means Rift cannot link the attachment reference directly.
  """
  @spec resolve_attachment_url(term()) :: nil
  def resolve_attachment_url(_attachment_ref), do: nil
end
