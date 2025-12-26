import Config

config :chat_backend, ChatBackend.Endpoint,
  url: [host: "localhost"],
  http: [port: 4000],
  server: true,
  secret_key_base: "super_secret_key_base_for_chat_app_development_only_change_in_production",
  pubsub_server: ChatBackend.PubSub

config :phoenix, :json_library, Jason

config :logger, level: :info
