defmodule Mix.Tasks.Rift.InstallTest do
  use ExUnit.Case, async: false

  setup do
    previous_shell = Mix.shell()
    Mix.shell(Mix.Shell.Process)

    path = Path.join(System.tmp_dir!(), "rift-install-test-#{System.unique_integer([:positive])}")
    File.rm_rf!(path)
    File.mkdir_p!(path)

    on_exit(fn ->
      Mix.shell(previous_shell)
      File.rm_rf!(path)
    end)

    %{path: path}
  end

  test "generates a host migration for Rift case tables", %{path: path} do
    Mix.Tasks.Rift.Install.run(["--path", path])

    assert_received {:mix_shell, :info, ["created " <> _migration_path]}

    [migration_path] = Path.wildcard(Path.join(path, "*_create_rift_tables.exs"))
    migration = File.read!(migration_path)

    assert {:ok, _quoted} = Code.string_to_quoted(migration)
    assert migration =~ "defmodule Rift.Test.Repo.Migrations.CreateRiftTables do"
    assert migration =~ "create table(:rift_cases, primary_key: false)"
    assert migration =~ "add :id, :binary_id, primary_key: true"
    assert migration =~ "add :tenant_key, :string"
    assert migration =~ "add :status, :string"
    assert migration =~ "add :details, :map"
    assert migration =~ "add :squid_mesh_run_id, :binary_id"
    assert migration =~ "create table(:rift_case_events, primary_key: false)"

    assert migration =~
             "add :case_id, references(:rift_cases, type: :binary_id, on_delete: :delete_all)"

    assert migration =~ "add :visible_to_originator, :boolean, null: false, default: false"
    assert migration =~ "create index(:rift_cases, [:tenant_key])"
    assert migration =~ "create index(:rift_case_events, [:case_id])"
  end

  test "skips generation when Rift tables migration already exists", %{path: path} do
    existing_path = Path.join(path, "20260101000000_create_rift_tables.exs")
    File.write!(existing_path, "# existing\n")

    Mix.Tasks.Rift.Install.run(["--path", path])

    assert_received {:mix_shell, :info, ["Rift already installed: " <> _migration_path]}
    assert Path.wildcard(Path.join(path, "*_create_rift_tables.exs")) == [existing_path]
  end
end
