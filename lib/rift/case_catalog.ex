defmodule Rift.CaseCatalog do
  @moduledoc """
  Builds catalog entries from host-defined Rift case types.
  """

  @type entry :: %{
          required(:case_type) => module(),
          required(:description) => String.t(),
          required(:key) => String.t(),
          required(:team) => String.t() | nil,
          required(:title) => String.t()
        }

  @doc """
  Returns presentation-ready catalog entries for case type modules.
  """
  @spec entries([module()]) :: [entry()]
  def entries(case_types) when is_list(case_types) do
    Enum.map(case_types, &entry/1)
  end

  @doc """
  Finds a catalog entry by its stable key.
  """
  @spec select([entry()], String.t()) :: entry() | nil
  def select(entries, key) when is_list(entries) and is_binary(key) do
    Enum.find(entries, &(&1.key == key))
  end

  defp entry(case_type) do
    %{
      case_type: case_type,
      description: description(case_type),
      key: key(case_type),
      team: optional_value(case_type, :team),
      title: case_type.title()
    }
  end

  defp key(case_type), do: Atom.to_string(case_type)

  defp description(case_type) do
    case optional_value(case_type, :description) do
      nil -> "Ready for operator review."
      description -> description
    end
  end

  defp optional_value(case_type, callback) do
    if Code.ensure_loaded?(case_type) and function_exported?(case_type, callback, 0) do
      apply(case_type, callback, [])
    end
  end
end
