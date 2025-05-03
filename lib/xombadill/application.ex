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

    children = [
      {Registry, keys: :unique, name: Xombadill.IrcRegistry},
      {Xombadill.HandlerRegistry, [default_handlers: default_handlers]},
      {Xombadill.IrcSupervisor,
       %{
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
       }}
    ]

    opts = [strategy: :one_for_one, name: Xombadill.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
