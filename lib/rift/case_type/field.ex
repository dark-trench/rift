defmodule Rift.CaseType.Field do
  @moduledoc """
  Structured declaration for a host-defined case form field.
  """

  @enforce_keys [:name, :type, :label]
  defstruct [
    :name,
    :type,
    :label,
    :default,
    :placeholder,
    :help_text,
    required: false,
    options: [],
    constraints: %{}
  ]

  @type t :: %__MODULE__{
          name: atom(),
          type: atom(),
          label: String.t(),
          required: boolean(),
          options: list() | {:resolver, atom()},
          default: term(),
          placeholder: String.t() | nil,
          help_text: String.t() | nil,
          constraints: map()
        }
end
