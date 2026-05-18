defmodule Rift.CaseTypeTest do
  use ExUnit.Case, async: true

  defmodule AccessChange do
    use Rift.CaseType

    @impl true
    def type, do: :access_change

    @impl true
    def title, do: "Access change"

    @impl true
    def fields do
      [
        field(:target_user_id, :select,
          label: "User",
          required: true,
          options: {:resolver, :target_user_id}
        ),
        field(:role, :select,
          label: "Role",
          required: true,
          options: [{"Operator", "operator"}, {"Admin", "admin"}]
        ),
        field(:reason, :textarea,
          label: "Reason",
          required: true
        )
      ]
    end

    @impl true
    def workflow, do: Rift.CaseTypeTest.AccessChangeWorkflow

    @impl true
    def trigger, do: :submit

    @impl true
    def build_payload(attrs, ctx) do
      %{
        target_user_id: attrs.target_user_id,
        role: attrs.role,
        reason: attrs.reason,
        opened_by: ctx.actor.id
      }
    end
  end

  defmodule AccessChangeWorkflow do
  end

  test "case type modules define host-owned form and workflow contracts" do
    assert AccessChange.type() == :access_change
    assert AccessChange.title() == "Access change"
    assert AccessChange.description() == nil
    assert AccessChange.team() == nil
    assert AccessChange.workflow() == AccessChangeWorkflow
    assert AccessChange.trigger() == :submit

    attrs = %{target_user_id: "user-2", role: "operator", reason: "Coverage"}
    ctx = %{actor: %{id: "user-1"}}

    assert AccessChange.build_payload(attrs, ctx) == %{
             target_user_id: "user-2",
             role: "operator",
             reason: "Coverage",
             opened_by: "user-1"
           }
  end

  test "fields are explicit data structures" do
    [target_user, role, reason] = AccessChange.fields()

    assert %Rift.CaseType.Field{
             name: :target_user_id,
             type: :select,
             label: "User",
             required: true,
             options: {:resolver, :target_user_id}
           } = target_user

    assert role.options == [{"Operator", "operator"}, {"Admin", "admin"}]
    assert reason.type == :textarea
  end

  test "rejects unsupported field types at declaration time" do
    assert_raise ArgumentError, ~r/unsupported Rift case field type/, fn ->
      Rift.CaseType.field(:name, :rich_text)
    end
  end

  test "rejects invalid field names" do
    assert_raise ArgumentError, ~r/field name must be an atom/, fn ->
      Rift.CaseType.field("name", :text)
    end
  end
end
