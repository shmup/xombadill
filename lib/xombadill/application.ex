defmodule Xombadill.Application do
  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    default_handlers = [
      Xombadill.Handlers.EchoHandler,
      Xombadill.Handlers.ReloadHandler,
      Xombadill.Handlers.RelayHandler
    ]

    config = %{
      default_server: :slashnet,
      default_channel: "#splat",
      servers: %{
        slashnet: %{
          host: "irc.slashnet.org",
          port: 6667,
          nick: "xombadill",
          channels: ["#splat"]
        },
        libera: %{
          host: "irc.libera.chat",
          port: 6667,
          nick: "xombadill",
          channels: ["#pissss"]
        }
      }
    }

    children = [
      {Registry, keys: :unique, name: Xombadill.IrcRegistry},
      {Xombadill.HandlerRegistry, [default_handlers: default_handlers]},
      {Xombadill.IrcSupervisor, config.servers},
      # New GenServer to store config
      {Xombadill.Config, config}
    ]

    opts = [strategy: :one_for_one, name: Xombadill.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
