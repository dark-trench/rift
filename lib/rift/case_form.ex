defmodule Rift.CaseForm do
  @moduledoc """
  Builds and validates originator forms for host-defined case types.
  """

  alias Rift.Resolver

  @type field :: %{
          required(:help_text) => String.t() | nil,
          required(:input_name) => String.t(),
          required(:label) => String.t(),
          required(:name) => atom(),
          required(:options) => list(),
          required(:placeholder) => String.t() | nil,
          required(:required?) => boolean(),
          required(:type) => atom(),
          required(:value) => term()
        }

  @type t :: %__MODULE__{
          case_type: module(),
          errors: %{optional(atom()) => String.t()},
          fields: [field()],
          params: map(),
          payload: map() | nil,
          submitted?: boolean()
        }

  defstruct case_type: nil,
            errors: %{},
            fields: [],
            params: %{},
            payload: nil,
            submitted?: false

  @doc """
  Builds a renderable form for a case type.
  """
  @spec new(module(), module(), term()) :: t()
  def new(case_type, resolver, actor) do
    %__MODULE__{
      case_type: case_type,
      fields: Enum.map(case_type.fields(), &field(&1, case_type, resolver, actor))
    }
  end

  @doc """
  Validates form params without building the host payload.
  """
  @spec validate(t(), map()) :: t()
  def validate(%__MODULE__{} = form, params) when is_map(params) do
    %{form | params: params, errors: errors(form.fields, params), submitted?: false, payload: nil}
  end

  @doc """
  Validates form params and builds the host-owned workflow payload.
  """
  @spec submit(t(), map(), map()) :: {:ok, t()} | {:error, t()}
  def submit(%__MODULE__{} = form, params, ctx) when is_map(params) and is_map(ctx) do
    form = validate(form, params)

    case form.errors do
      errors when map_size(errors) > 0 ->
        {:error, form}

      _errors ->
        payload = form.case_type.build_payload(attrs(form), ctx)
        {:ok, %{form | payload: payload, submitted?: true}}
    end
  end

  defp field(field, case_type, resolver, actor) do
    %{
      help_text: field.help_text,
      input_name: Atom.to_string(field.name),
      label: field.label,
      name: field.name,
      options: options(field, case_type, resolver, actor),
      placeholder: field.placeholder,
      required?: field.required,
      type: field.type,
      value: field.default
    }
  end

  defp options(%{options: {:resolver, field_name}}, case_type, resolver, actor) do
    Resolver.call_with_fallback(resolver, :resolve_select_options, [actor, case_type, field_name])
  end

  defp options(%{options: options}, _case_type, _resolver, _actor) when is_list(options),
    do: options

  defp options(_field, _case_type, _resolver, _actor), do: []

  defp errors(fields, params) do
    fields
    |> Enum.filter(&missing_required?(&1, params))
    |> Map.new(&{&1.name, "can't be blank"})
  end

  defp missing_required?(%{required?: false}, _params), do: false

  defp missing_required?(field, params) do
    blank?(Map.get(params, field.input_name, field.value))
  end

  defp blank?(value) when is_binary(value), do: String.trim(value) == ""
  defp blank?(nil), do: true
  defp blank?(_value), do: false

  defp attrs(form) do
    Map.new(form.fields, fn field ->
      {field.name, Map.get(form.params, field.input_name, field.value)}
    end)
  end
end
