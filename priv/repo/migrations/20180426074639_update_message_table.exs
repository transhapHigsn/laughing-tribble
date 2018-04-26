defmodule AuthEx.Repo.Migrations.UpdateMessageTable do
  use Ecto.Migration

  def change do
    create table(:rooms) do
      add :name, :string
      add :participant, {:array, :string}, default: []
      add :status, :string, default: "active"

      timestamps()
    end
  end
end