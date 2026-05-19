defmodule Mix.Tasks.Rift.Install do
  @moduledoc """
  Generates the host migration needed to persist Rift cases and events.
  """

  use Mix.Task

  @shortdoc "Generates Rift database migrations"

  @migration_name "create_rift_tables"

  @impl Mix.Task
  def run(args) do
    {opts, _argv} = OptionParser.parse!(args, strict: [path: :string])
    repo = Rift.Repo.get()

    path = Keyword.get_lazy(opts, :path, fn -> migrations_path(repo) end)
    File.mkdir_p!(path)

    case existing_migration(path) do
      nil -> create_migration(path)
      migration_path -> Mix.shell().info("Rift already installed: #{migration_path}")
    end
  end

  defp existing_migration(path) do
    path
    |> Path.join("*_#{@migration_name}.exs")
    |> Path.wildcard()
    |> List.first()
  end

  defp create_migration(path) do
    migration_path = Path.join(path, "#{timestamp()}_#{@migration_name}.exs")
    File.write!(migration_path, migration())
    Mix.shell().info("created #{migration_path}")
  end

  defp timestamp do
    Calendar.strftime(DateTime.utc_now(), "%Y%m%d%H%M%S")
  end

  defp migrations_path(repo) do
    repo
    |> Mix.EctoSQL.source_repo_priv()
    |> Path.join("migrations")
  end

  defp migration do
    repo = Rift.Repo.get()
    module = "#{inspect(repo)}.Migrations.CreateRiftTables"

    """
    defmodule #{module} do
      use Ecto.Migration

      def change do
        create table(:rift_cases, primary_key: false) do
          add :id, :binary_id, primary_key: true
          add :tenant_key, :string
          add :type, :string, null: false
          add :subject, :string, null: false
          add :status, :string, null: false
          add :team, :string
          add :opened_by_ref, :string, null: false
          add :assignee_ref, :string
          add :state, :map, null: false, default: %{}
          add :details, :map, null: false, default: %{}
          add :squid_mesh_run_id, :binary_id

          timestamps(type: :utc_datetime_usec)
        end

        create index(:rift_cases, [:tenant_key])
        create index(:rift_cases, [:type])
        create index(:rift_cases, [:status])
        create index(:rift_cases, [:team])
        create index(:rift_cases, [:assignee_ref])
        create index(:rift_cases, [:squid_mesh_run_id])
        create index(:rift_cases, [:updated_at])

        create table(:rift_case_events, primary_key: false) do
          add :id, :binary_id, primary_key: true
          add :case_id, references(:rift_cases, type: :binary_id, on_delete: :delete_all), null: false
          add :tenant_key, :string
          add :actor_ref, :string
          add :type, :string, null: false
          add :data, :map, null: false, default: %{}
          add :visible_to_originator, :boolean, null: false, default: false

          timestamps(type: :utc_datetime_usec)
        end

        create index(:rift_case_events, [:case_id])
        create index(:rift_case_events, [:tenant_key])
        create index(:rift_case_events, [:type])
        create index(:rift_case_events, [:inserted_at])
      end
    end
    """
  end
end
