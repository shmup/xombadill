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

  # handle connection messages
  def handle_info({:connected, server, port}, state) do
    Logger.info("Connected to #{server}:#{port}")
    ExIRC.Client.logon(state.client, state.nick, state.nick, state.nick, state.nick)
    {:noreply, state}
  end

  # handle login success
  def handle_info(:logged_in, state) do
    Logger.info("Logged in to server")
    Enum.each(state.channels, fn channel ->
      ExIRC.Client.join(state.client, channel)
    end)
    {:noreply, state}
  end

  # handle disconnection
  def handle_info({:disconnected, reason}, state) do
    Logger.warning("Disconnected: #{inspect(reason)}", [])
    # Attempt to reconnect after a delay
    Process.send_after(self(), :connect, 5000)
    {:noreply, state}
  end

  # reconnection handler
  def handle_info(:connect, state) do
    Logger.info("Attempting to connect to #{state.host}:#{state.port}")
    ExIRC.Client.connect!(state.client, state.host, state.port)
    {:noreply, state}
  end

  # handle joining a channel
  def handle_info({:joined, channel}, state) do
    Logger.info("Joined channel: #{channel}")
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

  # handle nick changes
  def handle_info({:nick_changed, old_nick, new_nick}, state) do
    Logger.info("Nick changed from #{old_nick} to #{new_nick}")
    {:noreply, state}
  end

  # handle users joining channels
  def handle_info({:joined, channel, user}, state) do
    Logger.debug("#{user} joined #{channel}")
    {:noreply, state}
  end

  # handle users leaving channels
  def handle_info({:left, channel, user}, state) do
    Logger.debug("#{user} left #{channel}")
    {:noreply, state}
  end

  # handle users quitting the server
  def handle_info({:quit, user, message}, state) do
    Logger.debug("#{user} quit: #{message}")
    {:noreply, state}
  end

  # catch-all for messages
  def handle_info(msg, state) do
    Logger.debug("Unhandled message: #{inspect(msg)}")
    {:noreply, state}
  end
end
