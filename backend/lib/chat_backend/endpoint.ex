defmodule ChatBackend.Endpoint do
  use Phoenix.Endpoint, otp_app: :chat_backend

  socket "/socket", ChatBackend.UserSocket,
    websocket: [check_origin: false],
    longpoll: false

  plug CORSPlug, origin: "*"

  plug Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Jason

  plug Plug.MethodOverride
  plug Plug.Head
end
