import Config

config :logger,
  level: :info

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:user_id],
  colors: [enabled: true],
  device: :user
