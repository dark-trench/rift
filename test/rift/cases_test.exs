defmodule Rift.CasesTest do
  use Rift.DataCase, async: true

  alias Rift.Cases
  alias Rift.Cases.Case
  alias Rift.Cases.Event

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
end
