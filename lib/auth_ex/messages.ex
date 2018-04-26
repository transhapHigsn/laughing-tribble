defmodule AuthEx.Messages do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  schema "messages" do
    field :message, :string
    field :room, :string
    field :username, :string

    timestamps()
  end

  @doc false
  def changeset(messages, attrs) do
    messages
    |> cast(attrs, [:message, :username, :room, :inserted_at, :updated_at])
    |> validate_required([:message, :username, :room, :inserted_at, :updated_at])
  end

  def get_messages() do
      AuthEx.Messages
      |> AuthEx.Repo.all()
  end

  def get_messages_by_room(room) do
    from(msg in AuthEx.Messages, where: msg.room == ^room)
    |> AuthEx.Repo.all()
  end
end
