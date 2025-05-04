defmodule Xombadill.Handlers.ReloadHandler do
  @moduledoc """
  A handler that reloads all handlers when a specific command is received.
  """

  @behaviour Xombadill.HandlerBehaviour
  require Logger
  alias Xombadill.ReloadCoordinator

  @impl true
  def handle_message(:channel_message, %{text: text, channel: channel, client: client} = _msg) do
    cond do
      text == "!reload" ->
        Task.start(fn -> ReloadCoordinator.reload_all_handlers(channel, client) end)

      String.starts_with?(text, "!loglevel ") ->
        level_str = String.replace(text, "!loglevel ", "")

        try do
          level = String.to_existing_atom(level_str)
          Logger.configure(level: level)
          ExIRC.Client.msg(client, :privmsg, channel, "✅ Log level changed to #{level_str}")
        rescue
          _ ->
            ExIRC.Client.msg(
              client,
              :privmsg,
              channel,
              "❌ Invalid log level. Use debug, info, warning, or error"
            )
        end

      true ->
        :ok
    end

    :ok
  end

  def handle_message(_type, _message), do: :ok
end
