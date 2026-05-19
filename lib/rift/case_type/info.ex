defmodule Rift.CaseType.Info do
  @moduledoc """
  Read helpers for compiled Rift case type Spark metadata.
  """

  alias Rift.CaseType.Field
  alias Spark.Dsl.Extension

  @doc """
  Returns the stable case type identifier.
  """
  @spec type(module()) :: atom()
  def type(case_type), do: required_opt(case_type, :type)

  @doc """
  Returns the human case type title.
  """
  @spec title(module()) :: String.t()
  def title(case_type), do: required_opt(case_type, :title)

  @doc """
  Returns the optional case type description.
  """
  @spec description(module()) :: String.t() | nil
  def description(case_type), do: Extension.get_opt(case_type, [:case_type], :description)

  @doc """
  Returns the optional case type team.
  """
  @spec team(module()) :: String.t() | nil
  def team(case_type), do: Extension.get_opt(case_type, [:case_type], :team)

  @doc """
  Returns the workflow module configured for this case type.
  """
  @spec workflow(module()) :: module()
  def workflow(case_type), do: required_opt(case_type, :workflow)

  @doc """
  Returns the workflow trigger configured for this case type.
  """
  @spec trigger(module()) :: atom()
  def trigger(case_type), do: required_opt(case_type, :trigger)

  @doc """
  Returns host-defined form field declarations.
  """
  @spec fields(module()) :: [Field.t()]
  def fields(case_type), do: Extension.get_entities(case_type, [:case_type, :fields])

  defp required_opt(case_type, key) do
    case Extension.get_opt(case_type, [:case_type], key) do
      nil ->
        raise ArgumentError,
              "missing required Rift case type DSL option #{inspect(key)} for #{inspect(case_type)}"

      value ->
        value
    end
  end
end
