defmodule Xombadill.Handlers.EchoHandler do
  @moduledoc """
  A simple example handler that echoes messages back to the channel.
  """
  @behaviour Xombadill.HandlerBehaviour
  require Logger

  @impl true
  def handle_message(:channel_message, %{text: text, nick: nick, channel: channel, client: client} = msg) do
    Logger.debug("EchoHandler received: #{inspect(%{text: text, nick: nick, channel: channel})}")

    # Don't echo !reload to avoid spamming if desired. But allow echo of messages that start with !reload too, if required by prompt
    ExIRC.Client.msg(client, :privmsg, channel, "#{nick} said: #{text}")
    :ok
  end

  def handle_message(type, message) do
    Logger.debug("EchoHandler ignoring message type: #{inspect(type)}, data: #{inspect(message)}")
    :ok
  end
end
