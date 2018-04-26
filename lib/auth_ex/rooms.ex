defmodule AuthEx.Rooms do
    use Ecto.Schema
    import Ecto.Changeset
  
    schema "rooms" do
      field :name, :string
      field :participant, {:array, :string}
      field :status, :string
  
      timestamps()
    end
  
    @doc false
    def changeset(rooms, attrs) do
      rooms
      |> cast(attrs, [:name, :participant, :status])
      |> validate_required([:name, :participant, :status])
    end
  
    def get_room?(room) do
        result = AuthEx.Repo.get_by(AuthEx.Rooms, name: room)
        if result == nil do
          false
        else
          true
        end
    end
  end
  