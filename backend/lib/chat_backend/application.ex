defmodule ChatBackend.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Phoenix.PubSub, name: ChatBackend.PubSub},
      ChatBackend.Endpoint
    ]

    opts = [strategy: :one_for_one, name: ChatBackend.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
