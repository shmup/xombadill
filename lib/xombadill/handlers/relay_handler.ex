defmodule Xombadill.Handlers.RelayHandler do
  @behaviour Xombadill.HandlerBehaviour
  require Logger

  @impl true
  def handle_message(
        :channel_message,
        %{
          text: text,
          nick: nick,
          channel: channel,
          server_id: server_id,
          server_host: server_host
        } = _msg
      ) do
    # Configure which messages to relay
    if server_id == :libera && channel == "#pissss" && contains_milestone?(text) do
      # Relay to slashnet #splat
      relay_message = "[#{server_host}/#{channel}] <#{nick}> #{text}"
      Xombadill.IrcClient.say(:slashnet, "#splat", relay_message)
    end

    :ok
  end

  def handle_message(_type, _message), do: :ok

  defp contains_milestone?(text) do
    # Logic to determine if a message is a milestone
    String.contains?(text, "has entered") ||
      String.contains?(text, "has reached") ||
      String.contains?(text, "has won") ||
      String.contains?(text, "hello")
  end
end
