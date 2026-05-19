defmodule Rift.Cases do
  @moduledoc """
  Persistence boundary for Rift cases and case timeline events.
  """

  alias Rift.CaseForm
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

  @doc """
  Opens a case from a host-defined case type and submitted form params.
  """
  @spec open_case(module(), map(), map(), module()) :: {:ok, Case.t()} | {:error, term()}
  def open_case(case_type, params, ctx, resolver)
      when is_atom(case_type) and is_map(params) and is_map(ctx) and is_atom(resolver) do
    form =
      case_type
      |> CaseForm.new(resolver, Map.fetch!(ctx, :actor))
      |> CaseForm.submit(params, ctx)

    case form do
      {:ok, submitted_form} ->
        attrs = case_type_open_attrs(case_type, submitted_form.payload, ctx)
        open_case(attrs)

      {:error, invalid_form} ->
        {:error, invalid_form}
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

  defp case_type_open_attrs(case_type, payload, ctx) do
    %{
      details: stringify_keys(payload),
      opened_by_ref: actor_ref(Map.fetch!(ctx, :actor)),
      subject: case_type.title(),
      team: optional_value(case_type, :team),
      tenant_key: Map.get(ctx, :tenant_key),
      type: Atom.to_string(case_type.type())
    }
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

  defp actor_ref(%{id: id}), do: to_string(id)
  defp actor_ref(actor), do: to_string(actor)

  defp optional_value(module, callback) do
    if function_exported?(module, callback, 0) do
      apply(module, callback, [])
    end
  end

  defp stringify_keys(value) when is_map(value) do
    Map.new(value, fn {key, value} -> {string_key(key), stringify_keys(value)} end)
  end

  defp stringify_keys(value) when is_list(value), do: Enum.map(value, &stringify_keys/1)
  defp stringify_keys(value), do: value

  defp string_key(key) when is_atom(key), do: Atom.to_string(key)
  defp string_key(key) when is_binary(key), do: key
  defp string_key(key), do: to_string(key)
end
