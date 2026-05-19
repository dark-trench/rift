defmodule Rift.CaseType do
  @moduledoc """
  Behaviour and DSL for host-defined Rift case types.

  A case type describes the human form Rift renders, plus the workflow and
  payload mapping the host app owns. Rift does not derive these fields from
  Squid Mesh workflow modules.
  """

  alias Rift.CaseType.Field
  alias Rift.CaseType.Info

  @field_types [:text, :textarea, :number, :boolean, :date, :select, :multi_select, :hidden]
  @field_options [:label, :required, :options, :default, :placeholder, :help_text, :constraints]

  @doc "Returns the stable case type identifier stored by Rift."
  @callback type() :: atom()

  @doc "Returns the human title shown in type pickers and case detail."
  @callback title() :: String.t()

  @doc "Returns optional helper copy for the case type."
  @callback description() :: String.t() | nil

  @doc "Returns the default team or queue that owns this case type."
  @callback team() :: String.t() | nil

  @doc "Returns the host-defined form fields Rift should render."
  @callback fields() :: [Field.t()]

  @doc "Returns the Squid Mesh workflow module Rift should start."
  @callback workflow() :: module()

  @doc "Returns the Squid Mesh trigger used when opening the case."
  @callback trigger() :: atom()

  @doc "Maps validated Rift form attributes into a Squid Mesh payload."
  @callback build_payload(attrs :: map(), ctx :: term()) :: map()

  @doc "Runs after Rift has opened the case and started the workflow."
  @callback after_opened(rift_case :: term(), ctx :: term()) :: hook_result()

  @doc "Runs after the approval action has succeeded in Squid Mesh."
  @callback after_approved(rift_case :: term(), ctx :: term()) :: hook_result()

  @doc "Runs after the rejection action has succeeded in Squid Mesh."
  @callback after_rejected(rift_case :: term(), ctx :: term()) :: hook_result()

  @doc "Runs after the cancellation action has succeeded in Squid Mesh."
  @callback after_cancelled(rift_case :: term(), ctx :: term()) :: hook_result()

  @doc "Runs after Rift assigns the case to an actor."
  @callback after_assigned(rift_case :: term(), ctx :: term()) :: hook_result()

  @doc "Runs after Rift releases the case from an actor."
  @callback after_released(rift_case :: term(), ctx :: term()) :: hook_result()

  @type hook_result :: :ok | {:ok, map()} | {:error, term()}

  @optional_callbacks description: 0,
                      team: 0,
                      after_opened: 2,
                      after_approved: 2,
                      after_rejected: 2,
                      after_cancelled: 2,
                      after_assigned: 2,
                      after_released: 2

  @doc """
  Imports the field DSL and default lifecycle hooks into a host case type.
  """
  @spec __using__(keyword()) :: Macro.t()
  defmacro __using__(_opts) do
    quote do
      use Rift.CaseType.Dsl

      @behaviour Rift.CaseType

      import Rift.CaseType, only: [field: 2, field: 3]

      @impl true
      def type, do: Info.type(__MODULE__)

      @impl true
      def title, do: Info.title(__MODULE__)

      @impl true
      def description, do: Info.description(__MODULE__)

      @impl true
      def team, do: Info.team(__MODULE__)

      @impl true
      def fields, do: Info.fields(__MODULE__)

      @impl true
      def workflow, do: Info.workflow(__MODULE__)

      @impl true
      def trigger, do: Info.trigger(__MODULE__)

      @impl true
      def after_opened(_rift_case, _ctx), do: :ok

      @impl true
      def after_approved(_rift_case, _ctx), do: :ok

      @impl true
      def after_rejected(_rift_case, _ctx), do: :ok

      @impl true
      def after_cancelled(_rift_case, _ctx), do: :ok

      @impl true
      def after_assigned(_rift_case, _ctx), do: :ok

      @impl true
      def after_released(_rift_case, _ctx), do: :ok

      defoverridable description: 0,
                     fields: 0,
                     team: 0,
                     title: 0,
                     trigger: 0,
                     type: 0,
                     workflow: 0,
                     after_opened: 2,
                     after_approved: 2,
                     after_rejected: 2,
                     after_cancelled: 2,
                     after_assigned: 2,
                     after_released: 2
    end
  end

  @doc """
  Builds a Rift form field declaration.
  """
  @spec field(atom(), atom(), keyword()) :: Field.t()
  def field(name, type, opts \\ []) do
    validate_name!(name)
    validate_type!(type)
    validate_opts!(opts)

    %Field{
      name: name,
      type: type,
      label: Keyword.get(opts, :label, default_label(name)),
      required: Keyword.get(opts, :required, false),
      options: Keyword.get(opts, :options, []),
      default: Keyword.get(opts, :default),
      placeholder: Keyword.get(opts, :placeholder),
      help_text: Keyword.get(opts, :help_text),
      constraints: Keyword.get(opts, :constraints, %{})
    }
  end

  defp validate_name!(name) when is_atom(name) and not is_nil(name), do: :ok

  defp validate_name!(_name) do
    raise ArgumentError, "Rift case field name must be an atom"
  end

  defp validate_type!(type) when type in @field_types, do: :ok

  defp validate_type!(type) do
    raise ArgumentError,
          "unsupported Rift case field type #{inspect(type)}; expected one of #{inspect(@field_types)}"
  end

  defp validate_opts!(opts) when is_list(opts) do
    unknown_opts = Keyword.keys(opts) -- @field_options

    case unknown_opts do
      [] ->
        validate_required!(Keyword.get(opts, :required, false))

      _unknown_opts ->
        raise ArgumentError, "unsupported Rift case field options: #{inspect(unknown_opts)}"
    end
  end

  defp validate_opts!(_opts) do
    raise ArgumentError, "Rift case field options must be a keyword list"
  end

  defp validate_required!(required) when is_boolean(required), do: :ok

  defp validate_required!(_required) do
    raise ArgumentError, "Rift case field :required option must be a boolean"
  end

  defp default_label(name) do
    name
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end
end
