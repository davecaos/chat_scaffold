defmodule ChatBackend.ChatChannel do
  use Phoenix.Channel

  @responses [
    "OK",
    "GOOD",
    "NICE",
    "GREAT",
    "PERFECT",
    "AWESOME",
    "EXCELLENT",
    "WONDERFUL",
    "FANTASTIC",
    "AMAZING",
    "SUPERB",
    "BRILLIANT"
  ]

  @impl true
  def join("chat:lobby", _payload, socket) do
    {:ok, %{status: "connected"}, socket}
  end

  def join("chat:" <> _room_id, _payload, socket) do
    {:ok, %{status: "connected"}, socket}
  end

  @impl true
  def handle_in("new_message", %{"text" => text}, socket) do
    response = Enum.random(@responses)

    # Broadcast the user's message to all clients
    broadcast!(socket, "user_message", %{text: text, from: "user"})

    # Send the bot response after a small delay simulation
    broadcast!(socket, "bot_message", %{text: response, from: "bot"})

    {:reply, {:ok, %{response: response}}, socket}
  end

  @impl true
  def handle_in("ping", _payload, socket) do
    {:reply, {:ok, %{message: "pong"}}, socket}
  end
end
