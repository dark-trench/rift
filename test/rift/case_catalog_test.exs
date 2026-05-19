defmodule Rift.CaseCatalogTest do
  use ExUnit.Case, async: true

  defmodule AccessChange do
    use Rift.CaseType

    case_type do
      type :access_change
      title "Access change"
      description "Request an operator review before changing access."
      team "admin"
      workflow Rift.CaseCatalogTest.AccessChangeWorkflow
      trigger :submit
    end

    @impl true
    def build_payload(attrs, _ctx), do: attrs
  end

  defmodule MinimalCaseType do
    def title, do: "Minimal case"
  end

  defmodule AccessChangeWorkflow do
  end

  test "builds presentation entries from case type modules" do
    assert [
             %{
               case_type: AccessChange,
               description: "Request an operator review before changing access.",
               key: "Elixir.Rift.CaseCatalogTest.AccessChange",
               slug: "access_change",
               team: "admin",
               title: "Access change"
             },
             %{
               case_type: MinimalCaseType,
               description: "Ready for operator review.",
               key: "Elixir.Rift.CaseCatalogTest.MinimalCaseType",
               slug: "Elixir.Rift.CaseCatalogTest.MinimalCaseType",
               team: nil,
               title: "Minimal case"
             }
           ] = Rift.CaseCatalog.entries([AccessChange, MinimalCaseType])
  end

  test "selects entries by stable module key without creating atoms" do
    entries = Rift.CaseCatalog.entries([AccessChange])

    assert %{case_type: AccessChange} =
             Rift.CaseCatalog.select(entries, "Elixir.Rift.CaseCatalogTest.AccessChange")

    assert Rift.CaseCatalog.select(entries, "Elixir.UnknownCaseType") == nil
  end

  test "selects entries by route slug without creating atoms" do
    entries = Rift.CaseCatalog.entries([AccessChange])

    assert %{case_type: AccessChange} = Rift.CaseCatalog.select_slug(entries, "access_change")
    assert Rift.CaseCatalog.select_slug(entries, "unknown_case") == nil
  end
end
