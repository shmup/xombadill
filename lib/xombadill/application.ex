defmodule Xombadill.Application do
  @moduledoc """
  The main Application module for the Xombadill bot.
  Responsible for supervising all processes, including the handler registries, IRC connections,
  and all other stateful components within the application.

  Starts different supervision trees depending on the environment (e.g., less during test).
  """
  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    default_handlers = [
      Xombadill.Handlers.ReloadHandler,
      Xombadill.Handlers.MilestoneHandler,
      Xombadill.Handlers.LearnDBHandler,
      Xombadill.Handlers.PlayerTrackerHandler,
      Xombadill.Handlers.BotRelayHandler,
      Xombadill.Handlers.LinkExplainHandler
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
          {Registry, keys: :duplicate, name: Xombadill.BotRelayRegistry},
          {Xombadill.HandlerRegistry, [default_handlers: default_handlers]},
          {Xombadill.IrcSupervisor, config.servers},
          {Xombadill.TrackedPlayers, ["shmup", "neckro23", "ces", "helicomatic", "Lucai"]},
          {Xombadill.Config, config}
        ]
      end

    opts = [strategy: :one_for_one, name: Xombadill.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
