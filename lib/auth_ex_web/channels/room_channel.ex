defmodule AuthExWeb.RoomChannel do
  use Phoenix.Channel
  alias AuthExWeb.Presence
  use Timex

  def join("room:" <> room_id, payload, socket) do
    send(self, :after_join)
    if authorized?(payload) do
      channelName = "room.#{room_id}"
      {:ok, %{channel: channelName}, assign(socket, :room_id, room_id)}
      # {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (room:lobby).
  def handle_in("shout", payload, socket) do
    broadcast socket, "shout", payload
    {:noreply, socket}
  end

  def handle_in("message:new", message, socket) do
    local = Timex.local
    room = Map.get(message, "room")
    msg = Map.get(message, "message")
    username = socket.assigns.user
    payload = %{
      message: msg, 
      username: username,
      room: room, 
      inserted_at: local, 
      updated_at: local
    }
    
    check_room = AuthEx.Rooms.get_room?(room)

    if check_room do
      AuthEx.Messages.changeset(%AuthEx.Messages{}, payload)
      |> AuthEx.Repo.insert
      broadcast! socket, "message:new", %{
        user: socket.assigns.user,
        body: message,
        timestamp: Timex.local
      }
    end

    {:noreply, socket}
  end

  def handle_in("screen:reload", _, socket) do
      room = socket.assigns.room_id
      AuthEx.Messages.get_messages_by_room(room)
      |> Enum.each(fn msg -> push(socket, "message:new", %{
        user: msg.username,
        body: msg.message,
        timestamp: msg.inserted_at
      }) end)
      {:noreply, socket}
  end

  def handle_info(:after_join, socket) do
    broadcast socket, "reload", %{}
    {:ok, _} = Presence.track(socket, socket.assigns.user, %{
      online_at: DateTime.to_unix(Timex.local, :milliseconds)
    })
    push socket, "presence_state", Presence.list(socket)
    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end
