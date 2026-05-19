defmodule Rift.CaseType.Dsl do
  @moduledoc """
  Spark DSL wrapper for Rift case type declarations.
  """

  use Spark.Dsl,
    default_extensions: [
      extensions: [Rift.CaseType.SparkExtension]
    ]
end
