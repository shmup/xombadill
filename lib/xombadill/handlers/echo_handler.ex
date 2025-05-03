defmodule Xombadill.Handlers.EchoHandler do
  @moduledoc """
  A simple example handler that echoes messages back to the channel.
  """
  @behaviour Xombadill.HandlerBehaviour
  require Logger

  @impl true
  def handle_message(:channel_message, message) do
    Logger.debug("EchoHandler received channel message: #{inspect(message)}")

    with %{text: text, nick: nick, channel: channel, client: client} <- message do
      Logger.debug("EchoHandler processing with text: #{text}, nick: #{nick}")
      ExIRC.Client.msg(client, :privmsg, channel, "#{nick} said: #{text}")
      Logger.debug("EchoHandler sent reply")
    else
      _ -> Logger.warning("EchoHandler couldn't process message: #{inspect(message)}")
    end

    :ok
  end

  def handle_message(type, message) do
    Logger.debug("EchoHandler ignoring message type: #{inspect(type)}, data: #{inspect(message)}")
    :ok
  end
end
