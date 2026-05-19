defmodule Rift.CasesTest do
  use Rift.DataCase, async: true

  alias Rift.Cases
  alias Rift.Cases.Case
  alias Rift.Cases.Event

  defmodule Resolver do
  end

  defmodule AccessChange do
    use Rift.CaseType

    case_type do
      type :access_change
      title "Access change"
      description "Ask an operator to review an access change."
      team "identity"
      workflow Rift.CasesTest.Workflow
      trigger :submit

      fields do
        field :target_user_id, :text, label: "User", required: true
        field :reason, :textarea, label: "Reason", required: true
      end
    end

    @impl true
    def build_payload(attrs, ctx) do
      %{
        opened_by: ctx.actor.id,
        reason: attrs.reason,
        target_user_id: attrs.target_user_id
      }
    end
  end

  defmodule Workflow do
  end

  describe "open_case/1" do
    test "persists a case and case_opened event atomically" do
      attrs = %{
        tenant_key: "tenant-1",
        type: "access_change",
        subject: "Access change for Ada",
        team: "admin",
        opened_by_ref: "user-ada",
        details: %{"role" => "admin"},
        state: %{"payload" => %{"target_user_id" => "user-grace"}}
      }

      assert {:ok, %Case{} = rift_case} = Cases.open_case(attrs)

      assert rift_case.id
      assert rift_case.tenant_key == "tenant-1"
      assert rift_case.type == "access_change"
      assert rift_case.subject == "Access change for Ada"
      assert rift_case.status == "open"
      assert rift_case.team == "admin"
      assert rift_case.opened_by_ref == "user-ada"
      assert rift_case.assignee_ref == nil
      assert rift_case.details == %{"role" => "admin"}
      assert rift_case.state == %{"payload" => %{"target_user_id" => "user-grace"}}
      assert rift_case.squid_mesh_run_id == nil

      assert [%Event{} = event] = Rift.Repo.get().all(Event)
      assert event.case_id == rift_case.id
      assert event.tenant_key == "tenant-1"
      assert event.actor_ref == "user-ada"
      assert event.type == "case_opened"
      assert event.visible_to_originator == true

      assert event.data == %{
               "subject" => "Access change for Ada",
               "type" => "access_change"
             }
    end

    test "returns changeset errors and does not create an event for invalid case data" do
      assert {:error, %Ecto.Changeset{} = changeset} = Cases.open_case(%{type: "access_change"})

      assert %{
               opened_by_ref: ["can't be blank"],
               subject: ["can't be blank"]
             } = errors_on(changeset)

      assert Rift.Repo.get().aggregate(Case, :count) == 0
      assert Rift.Repo.get().aggregate(Event, :count) == 0
    end

    test "normalizes caller-supplied status to open" do
      attrs = %{
        type: "access_change",
        subject: "Access change for Ada",
        status: "approved",
        opened_by_ref: "user-ada"
      }

      assert {:ok, %Case{} = rift_case} = Cases.open_case(attrs)
      assert rift_case.status == "open"
      assert Rift.Repo.get().aggregate(Event, :count) == 1
    end

    test "accepts string-keyed transport attributes" do
      attrs = %{
        "type" => "access_change",
        "subject" => "Access change for Ada",
        "opened_by_ref" => "user-ada",
        "details" => %{"role" => "admin"}
      }

      assert {:ok, %Case{} = rift_case} = Cases.open_case(attrs)
      assert rift_case.status == "open"
      assert rift_case.details == %{"role" => "admin"}
    end
  end

  describe "open_case/4" do
    test "opens a case from a host case type and submitted form params" do
      assert {:ok, %Case{} = rift_case} =
               Cases.open_case(
                 AccessChange,
                 %{
                   "target_user_id" => "user-ada",
                   "reason" => "Need production access"
                 },
                 %{
                   actor: %{id: "originator-1"},
                   tenant_key: "tenant-1"
                 },
                 Resolver
               )

      assert rift_case.type == "access_change"
      assert rift_case.subject == "Access change"
      assert rift_case.status == "open"
      assert rift_case.team == "identity"
      assert rift_case.opened_by_ref == "originator-1"
      assert rift_case.tenant_key == "tenant-1"
      assert rift_case.squid_mesh_run_id == nil

      assert rift_case.details == %{
               "opened_by" => "originator-1",
               "reason" => "Need production access",
               "target_user_id" => "user-ada"
             }

      assert [event] = Rift.Repo.get().all(Event)
      assert event.case_id == rift_case.id
      assert event.type == "case_opened"
      assert event.actor_ref == "originator-1"
      assert event.tenant_key == "tenant-1"
      assert event.visible_to_originator

      assert event.data == %{
               "subject" => "Access change",
               "type" => "access_change"
             }
    end

    test "does not persist a case when generic form validation fails" do
      assert {:error, form} =
               Cases.open_case(
                 AccessChange,
                 %{"target_user_id" => ""},
                 %{actor: %{id: "originator-1"}, tenant_key: "tenant-1"},
                 Resolver
               )

      assert form.errors == %{reason: "can't be blank", target_user_id: "can't be blank"}
      assert Rift.Repo.get().aggregate(Case, :count) == 0
      assert Rift.Repo.get().aggregate(Event, :count) == 0
    end
  end

  describe "list_inbox_cases/1" do
    test "lists open cases for the tenant and available case types" do
      assert {:ok, access_case} =
               Cases.open_case(%{
                 tenant_key: "tenant-1",
                 type: "access_change",
                 subject: "Access change",
                 team: "identity",
                 opened_by_ref: "originator-1"
               })

      assert {:ok, _other_tenant_case} =
               Cases.open_case(%{
                 tenant_key: "tenant-2",
                 type: "access_change",
                 subject: "Other tenant",
                 opened_by_ref: "originator-2"
               })

      assert {:ok, _other_type_case} =
               Cases.open_case(%{
                 tenant_key: "tenant-1",
                 type: "vendor_onboarding",
                 subject: "Vendor onboarding",
                 opened_by_ref: "originator-3"
               })

      assert Cases.list_inbox_cases(%{tenant_key: "tenant-1", case_types: [AccessChange]}) == [
               access_case
             ]
    end
  end

  describe "fetch_inbox_case/2" do
    test "fetches an open case for the tenant and available case type" do
      assert {:ok, rift_case} =
               Cases.open_case(%{
                 tenant_key: "tenant-1",
                 type: "access_change",
                 subject: "Access change",
                 team: "identity",
                 opened_by_ref: "originator-1",
                 details: %{"reason" => "Coverage"}
               })

      assert {:ok, %Case{} = fetched_case} =
               Cases.fetch_inbox_case(rift_case.id, %{
                 tenant_key: "tenant-1",
                 case_types: [AccessChange]
               })

      assert fetched_case.id == rift_case.id
      assert fetched_case.details == %{"reason" => "Coverage"}
    end

    test "does not fetch cases from another tenant" do
      assert {:ok, rift_case} =
               Cases.open_case(%{
                 tenant_key: "tenant-2",
                 type: "access_change",
                 subject: "Access change",
                 opened_by_ref: "originator-1"
               })

      assert Cases.fetch_inbox_case(rift_case.id, %{
               tenant_key: "tenant-1",
               case_types: [AccessChange]
             }) == {:error, :not_found}
    end

    test "does not fetch unavailable case types" do
      assert {:ok, rift_case} =
               Cases.open_case(%{
                 tenant_key: "tenant-1",
                 type: "vendor_onboarding",
                 subject: "Vendor onboarding",
                 opened_by_ref: "originator-1"
               })

      assert Cases.fetch_inbox_case(rift_case.id, %{
               tenant_key: "tenant-1",
               case_types: [AccessChange]
             }) == {:error, :not_found}
    end

    test "does not raise on malformed case ids" do
      assert Cases.fetch_inbox_case("not-a-case-id", %{
               tenant_key: "tenant-1",
               case_types: [AccessChange]
             }) == {:error, :not_found}
    end
  end
end
