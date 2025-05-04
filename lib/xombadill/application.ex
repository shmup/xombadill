defmodule Xombadill.Application do
  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    default_handlers = [
      Xombadill.Handlers.ReloadHandler,
      Xombadill.Handlers.RelayHandler,
      Xombadill.Handlers.MilestoneHandler,
      Xombadill.Handlers.LearnDBHandler,
      Xombadill.Handlers.PlayerTrackerHandler
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
          channels: ["#pissss", "#crawl-octolog"]
        }
      }
    }

    children =
      if Mix.env() == :test do
        # In test environment, just start the registry and config
        [
          {Registry, keys: :unique, name: Xombadill.IrcRegistry},
          {Xombadill.Config, config}
        ]
      else
        # In normal operation, start everything
        [
          {Registry, keys: :unique, name: Xombadill.IrcRegistry},
          {Xombadill.HandlerRegistry, [default_handlers: default_handlers]},
          {Xombadill.IrcSupervisor, config.servers},
          {Xombadill.TrackedPlayers, ["shmup"]},
          {Xombadill.Config, config}
        ]
      end

    opts = [strategy: :one_for_one, name: Xombadill.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
