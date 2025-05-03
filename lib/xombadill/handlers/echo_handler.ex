defmodule Xombadill.Handlers.EchoHandler do
  @moduledoc """
  A simple example handler that echoes messages back to the channel.
  """
  @behaviour Xombadill.HandlerBehaviour
  require Logger

  @impl true
  def handle_message(:channel_message, %{text: text, nick: nick, channel: channel, client: client}) do
    if String.starts_with?(text, "!echo ") do
      response = String.trim_leading(text, "!echo ")
      ExIRC.Client.msg(client, :privmsg, channel, "#{nick} said: #{response}")
    end
  end

  def handle_message(_type, _message), do: :ok
end
