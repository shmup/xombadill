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
      unless String.starts_with?(text, "!") or channel != "#splat" do
        try do
          # Handle both actual ExIRC.Client and mock client implementations
          cond do
            is_atom(client) ->
              # Handle case where client is a module that implements msg/4
              apply(client, :msg, [client, :privmsg, channel, "#{nick} said: #{text}"])

            true ->
              # Default to ExIRC.Client for regular clients
              ExIRC.Client.msg(client, :privmsg, channel, "#{nick} said: #{text}")
          end

          Logger.debug("EchoHandler sent reply")
        rescue
          e -> Logger.error("Error sending message: #{inspect(e)}")
        end
      else
        Logger.debug("EchoHandler skipping message starting with !")
      end
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
