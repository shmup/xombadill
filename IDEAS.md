# Minimal IRC Bot for DCSS Relay

Let's create a simple IRC bot that connects to channels and outputs messages to stdout.

## 1. Add IRC Dependency

Edit `mix.exs`:

```elixir
defp deps do
  [
    {:exirc, "~> 2.0"}  # Simple IRC client library
  ]
end
```

Run:
```bash
mix deps.get
```

## 2. Create a Simple IRC Client

Create `lib/xombadill/irc_client.ex`:

```elixir
defmodule Xombadill.IrcClient do
  use GenServer
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(opts) do
    client = ExIRC.start_link!()

    state = %{
      client: client,
      host: opts[:host] || "irc.libera.chat",
      port: opts[:port] || 6667,
      nick: opts[:nick] || "xombadill",
      channels: opts[:channels] || ["#crawl"]
    }

    ExIRC.Client.add_handler(client, self())
    ExIRC.Client.connect!(client, state.host, state.port)

    {:ok, state}
  end

  # Handle connection established
  def handle_info(:connected, state) do
    ExIRC.Client.logon(state.client, state.nick, state.nick, state.nick)
    {:noreply, state}
  end

  # Handle login success
  def handle_info(:logged_in, state) do
    Enum.each(state.channels, fn channel ->
      ExIRC.Client.join(state.client, channel)
    end)
    {:noreply, state}
  end

  # Handle channel messages
  def handle_info({:received, msg, info, channel}, state) do
    IO.puts("#{channel} #{info.nick}: #{msg}")
    {:noreply, state}
  end

  # Handle private messages
  def handle_info({:received, msg, info}, state) do
    IO.puts("PRIVATE #{info.nick}: #{msg}")
    {:noreply, state}
  end

  # Catch-all for messages
  def handle_info(_msg, state) do
    {:noreply, state}
  end
end
```

## 3. Update Application Supervisor

Edit `lib/xombadill/application.ex`:

```elixir
defmodule Xombadill.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Xombadill.IrcClient, [
        nick: "xombadill_bot",
        channels: ["#crawl", "#crawl-dev"]  # Add your DCSS channels here
      ]}
    ]

    opts = [strategy: :one_for_one, name: Xombadill.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

## 4. Run the Bot

```bash
mix run --no-halt
```

This will:
1. Connect to Libera Chat IRC
2. Join the specified DCSS channels
3. Output all messages to stdout in the format: `#channel nickname: message`
4. Handle private messages with the prefix `PRIVATE`

You can customize the channels, server, and nickname in the application.ex file.
