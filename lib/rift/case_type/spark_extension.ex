defmodule Rift.CaseType.SparkExtension do
  @moduledoc """
  Spark extension that defines Rift case type metadata and fields.
  """

  alias Rift.CaseType.Field

  @field_types [:text, :textarea, :number, :boolean, :date, :select, :multi_select, :hidden]

  @field_schema [
    name: [
      type: :atom,
      required: true,
      doc: "The submitted field name."
    ],
    type: [
      type: {:in, @field_types},
      required: true,
      doc: "The field input type."
    ],
    label: [
      type: :string,
      required: false,
      doc: "The human label shown for the field."
    ],
    required: [
      type: :boolean,
      default: false,
      doc: "Whether the field is required."
    ],
    options: [
      type: :any,
      default: [],
      doc: "Static options or {:resolver, field_name} for select fields."
    ],
    default: [
      type: :any,
      required: false,
      doc: "Default field value."
    ],
    placeholder: [
      type: :string,
      required: false,
      doc: "Optional placeholder text."
    ],
    help_text: [
      type: :string,
      required: false,
      doc: "Optional help text."
    ],
    constraints: [
      type: :map,
      default: %{},
      doc: "Generic validation constraints."
    ]
  ]

  @field %Spark.Dsl.Entity{
    name: :field,
    target: Field,
    args: [:name, :type],
    schema: @field_schema,
    identifier: :name,
    transform: {__MODULE__, :put_default_label, []}
  }

  @fields %Spark.Dsl.Section{
    name: :fields,
    entities: [@field],
    describe: "Declares Rift case form fields."
  }

  @case_type_schema [
    type: [
      type: :atom,
      required: true,
      doc: "The stable case type identifier."
    ],
    title: [
      type: :string,
      required: true,
      doc: "The human title shown in case type pickers and details."
    ],
    description: [
      type: :string,
      required: false,
      doc: "Optional helper copy for the case type."
    ],
    team: [
      type: :string,
      required: false,
      doc: "Default team or queue for this case type."
    ],
    workflow: [
      type: :atom,
      required: true,
      doc: "The Squid Mesh workflow module Rift should start."
    ],
    trigger: [
      type: :atom,
      required: true,
      doc: "The Squid Mesh trigger used when opening the case."
    ]
  ]

  @case_type %Spark.Dsl.Section{
    name: :case_type,
    schema: @case_type_schema,
    sections: [@fields],
    describe: "Declares Rift case type metadata."
  }

  use Spark.Dsl.Extension, sections: [@case_type]

  @doc false
  @spec put_default_label(Field.t()) :: {:ok, Field.t()}
  def put_default_label(%Field{label: nil} = field) do
    {:ok, %{field | label: default_label(field.name)}}
  end

  def put_default_label(%Field{} = field), do: {:ok, field}

  defp default_label(name) do
    name
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end
end
