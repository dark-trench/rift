defmodule Rift.CaseFormTest do
  use ExUnit.Case, async: true

  defmodule Resolver do
    def resolve_select_options(_actor, Rift.CaseFormTest.CaseType, :target_user_id) do
      [{"Ada Lovelace", "user-ada"}, {"Grace Hopper", "user-grace"}]
    end
  end

  defmodule CaseType do
    use Rift.CaseType

    case_type do
      type :access_change
      title "Access change"
      workflow Rift.CaseFormTest.Workflow
      trigger :submit

      fields do
        field :target_user_id, :select,
          label: "User",
          required: true,
          options: {:resolver, :target_user_id}

        field :role, :select,
          label: "Role",
          required: true,
          options: [{"Operator", "operator"}, {"Admin", "admin"}]

        field :reason, :textarea,
          label: "Reason",
          required: true
      end
    end

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

  defmodule Workflow do
  end

  test "builds renderable fields with resolver-backed options" do
    form = Rift.CaseForm.new(CaseType, Resolver, %{id: "operator-1"})

    assert %{
             fields: [
               %{
                 input_name: "target_user_id",
                 label: "User",
                 options: [{"Ada Lovelace", "user-ada"}, {"Grace Hopper", "user-grace"}],
                 required?: true,
                 type: :select
               },
               %{input_name: "role", options: [{"Operator", "operator"}, {"Admin", "admin"}]},
               %{input_name: "reason", type: :textarea}
             ]
           } = form
  end

  test "validates required fields without building a payload" do
    form = Rift.CaseForm.new(CaseType, Resolver, %{id: "operator-1"})

    assert {:error, form} = Rift.CaseForm.submit(form, %{}, %{actor: %{id: "operator-1"}})

    assert form.errors == %{
             reason: "can't be blank",
             role: "can't be blank",
             target_user_id: "can't be blank"
           }

    refute form.submitted?
  end

  test "builds the host payload after successful validation" do
    form = Rift.CaseForm.new(CaseType, Resolver, %{id: "operator-1"})

    assert {:ok, submitted_form} =
             Rift.CaseForm.submit(
               form,
               %{
                 "target_user_id" => "user-ada",
                 "role" => "admin",
                 "reason" => "Coverage"
               },
               %{actor: %{id: "operator-1"}}
             )

    assert submitted_form.submitted?

    assert submitted_form.payload == %{
             target_user_id: "user-ada",
             role: "admin",
             reason: "Coverage",
             opened_by: "operator-1"
           }
  end
end
