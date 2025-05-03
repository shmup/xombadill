import Config

config :logger,
  level: :debug

config :logger, :console,
  format: "$time $metadata[$level] $message",
  metadata: [:user_id],
  colors: [enabled: true],
  device: :user
