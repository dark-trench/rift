defmodule Rift.Cases do
  @moduledoc """
  Persistence boundary for Rift cases and case timeline events.
  """

  alias Ecto.Multi
  alias Rift.Cases.Case
  alias Rift.Cases.Event
  alias Rift.Repo

  @doc """
  Opens a Rift case and appends its public `case_opened` event atomically.
  """
  @spec open_case(map()) ::
          {:ok, Case.t()} | {:error, Ecto.Changeset.t()} | {:error, atom(), term()}
  def open_case(attrs) when is_map(attrs) do
    repo = Repo.get()
    attrs = put_open_status(attrs)

    Multi.new()
    |> Multi.insert(:case, Case.changeset(%Case{}, attrs))
    |> Multi.insert(:case_opened, fn %{case: rift_case} ->
      Event.changeset(%Event{}, case_opened_attrs(rift_case))
    end)
    |> repo.transaction()
    |> case do
      {:ok, %{case: rift_case}} -> {:ok, rift_case}
      {:error, :case, changeset, _changes} -> {:error, changeset}
      {:error, step, reason, _changes} -> {:error, step, reason}
    end
  end

  defp put_open_status(attrs) do
    if Enum.any?(Map.keys(attrs), &is_binary/1) do
      Map.put(attrs, "status", "open")
    else
      Map.put(attrs, :status, "open")
    end
  end

  defp case_opened_attrs(rift_case) do
    %{
      case_id: rift_case.id,
      tenant_key: rift_case.tenant_key,
      actor_ref: rift_case.opened_by_ref,
      type: "case_opened",
      data: %{
        subject: rift_case.subject,
        type: rift_case.type
      },
      visible_to_originator: true
    }
  end
end
