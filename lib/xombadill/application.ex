defmodule Xombadill.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    default_handlers = [
      Xombadill.Handlers.EchoHandler,
      Xombadill.Handlers.ReloadHandler
    ]

    children = [
      {Xombadill.HandlerRegistry, [default_handlers: default_handlers]},
      {Xombadill.IrcClient,
       [
         nick: "xombadill",
         channels: ["#splat"]
       ]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Xombadill.Supervisor]
    result = Supervisor.start_link(children, opts)

    # Log registered handlers after supervisor start for confirmation
    # Optional: Use spawn or Task.start to avoid blocking if registry call is slow,
    # but usually direct call is fine here.
    Logger.info("Attempting to list initially registered handlers...")
    handlers = Xombadill.HandlerRegistry.list_handlers()
    Logger.info("Initially registered handlers: #{inspect(handlers)}")

    result
  end

  @doc """
  Helper function to load and register a new handler at runtime.
  """
  def load_handler(module) when is_atom(module) do
    Code.ensure_loaded(module)

    Xombadill.HandlerRegistry.register(module)
  end
end
