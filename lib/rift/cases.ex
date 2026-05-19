defmodule Rift.Cases do
  @moduledoc """
  Persistence boundary for Rift cases and case timeline events.
  """

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

    result =
      repo.transaction(fn ->
        with {:ok, rift_case} <- insert_case(repo, attrs),
             :ok <- insert_case_opened_event(repo, rift_case) do
          rift_case
        else
          {:error, step, reason} -> repo.rollback({step, reason})
        end
      end)

    case result do
      {:ok, rift_case} -> {:ok, rift_case}
      {:error, {:case, %Ecto.Changeset{} = changeset}} -> {:error, changeset}
      {:error, {step, reason}} -> {:error, step, reason}
    end
  end

  defp insert_case(repo, attrs) do
    case repo.insert(Case.changeset(%Case{}, attrs)) do
      {:ok, rift_case} -> {:ok, rift_case}
      {:error, %Ecto.Changeset{} = changeset} -> {:error, :case, changeset}
    end
  end

  defp insert_case_opened_event(repo, rift_case) do
    case repo.insert(Event.changeset(%Event{}, case_opened_attrs(rift_case))) do
      {:ok, _event} -> :ok
      {:error, %Ecto.Changeset{} = changeset} -> {:error, :case_opened, changeset}
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
