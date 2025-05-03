defmodule Xombadill.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    children = [
      {Xombadill.HandlerRegistry, []},
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

    register_default_handlers()

    result
  end

  @doc """
  Register the default handlers that should be active on startup.
  """
  def register_default_handlers do
    # Register the echo handler
    Xombadill.HandlerRegistry.register(Xombadill.Handlers.EchoHandler)
    Logger.info("Registered default handlers")
  end

  @doc """
  Helper function to load and register a new handler at runtime.
  """
  def load_handler(module) when is_atom(module) do
    Code.ensure_loaded(module)

    Xombadill.HandlerRegistry.register(module)
  end
end
