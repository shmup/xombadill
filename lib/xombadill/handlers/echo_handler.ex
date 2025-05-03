defmodule Xombadill.Handlers.EchoHandler do
  @moduledoc """
  A simple example handler that echoes messages back to the channel.
  """
  @behaviour Xombadill.HandlerBehaviour
  require Logger

  @impl true
  def handle_message(:channel_message, %{text: text, nick: nick, channel: channel, client: client}) do
    Logger.debug("EchoHandler received: #{inspect(%{text: text, nick: nick, channel: channel})}")

    if String.starts_with?(text, "!echo ") do
      response = String.trim_leading(text, "!echo ")
      Logger.info("Echoing: #{response}")
      ExIRC.Client.msg(client, :privmsg, channel, "#{nick} said: #{response}")
    end
  end

  def handle_message(type, message) do
    Logger.debug("EchoHandler ignoring message type: #{inspect(type)}, data: #{inspect(message)}")
    :ok
  end
end
