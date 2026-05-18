defmodule Rift.ResolverTest do
  use ExUnit.Case, async: true

  alias Rift.Resolver

  defmodule PartialResolver do
    @behaviour Rift.Resolver

    @impl true
    def resolve_actor(_conn), do: %{id: "user-1"}

    @impl true
    def resolve_case_types(_actor), do: [Rift.ResolverTest.AccessChange]
  end

  defmodule AccessChange do
  end

  describe "call_with_fallback/3" do
    test "calls host resolver implementations when present" do
      assert Resolver.call_with_fallback(PartialResolver, :resolve_actor, [%Plug.Conn{}]) ==
               %{id: "user-1"}

      assert Resolver.call_with_fallback(PartialResolver, :resolve_case_types, [%{id: "user-1"}]) ==
               [AccessChange]
    end

    test "falls back to Rift defaults for optional resolver callbacks" do
      actor = %{id: "user-1"}

      assert Resolver.call_with_fallback(PartialResolver, :resolve_tenant, [actor]) == nil
      assert Resolver.call_with_fallback(PartialResolver, :resolve_access, [actor]) == :originator

      assert Resolver.call_with_fallback(PartialResolver, :resolve_select_options, [
               actor,
               AccessChange,
               :role
             ]) == []

      assert Resolver.call_with_fallback(PartialResolver, :resolve_actor_label, ["user-1"]) ==
               "user-1"

      assert Resolver.call_with_fallback(PartialResolver, :resolve_attachment_url, ["file-1"]) ==
               nil
    end
  end
end
