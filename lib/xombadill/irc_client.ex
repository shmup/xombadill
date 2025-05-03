defmodule Xombadill.IrcClient do
  use GenServer
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(opts) do
    {:ok, client} = ExIRC.start_link!()

    state = %{
      client: client,
      host: opts[:host] || "irc.slashnet.org",
      port: opts[:port] || 6667,
      nick: opts[:nick] || "xombadill",
      channels: opts[:channels] || ["#splat"]
    }

    ExIRC.Client.add_handler(client, self())
    ExIRC.Client.connect!(client, state.host, state.port)

    {:ok, state}
  end

  # handle connection established
  def handle_info(:connected, state) do
    ExIRC.Client.logon(state.client, state.nick, state.nick, state.nick, state.nick)
    {:noreply, state}
  end

  # handle login success
  def handle_info(:logged_in, state) do
    Enum.each(state.channels, fn channel ->
      ExIRC.Client.join(state.client, channel)
    end)
    {:noreply, state}
  end

  # handle channel messages
  def handle_info({:received, msg, info, channel}, state) do
    IO.puts("#{channel} #{info.nick}: #{msg}")
    {:noreply, state}
  end

  # handle private messages
  def handle_info({:received, msg, info}, state) do
    IO.puts("PRIVATE #{info.nick}: #{msg}")
    {:noreply, state}
  end

  # catch-all for messages
  def handle_info(_msg, state) do
    {:noreply, state}
  end
end
