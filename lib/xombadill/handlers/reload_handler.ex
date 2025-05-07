defmodule Xombadill.Handlers.ReloadHandler do
  @moduledoc """
  Handler that provides IRC commands to reload, start, or stop handler modules
  and change log level at runtime, primarily for debugging and administration.
  """

  @behaviour Xombadill.HandlerBehaviour
  require Logger
  alias Xombadill.ReloadCoordinator

  @impl true
  def handle_message(:channel_message, %{text: text, channel: channel, client: client} = _msg) do
    cond do
      text == "!reload" ->
        Task.start(fn -> ReloadCoordinator.reload_all_handlers(channel, client) end)

      String.match?(text, ~r/^!reload\s+(.+)$/) ->
        [_, module_name] = Regex.run(~r/^!reload\s+(.+)$/, text)
        # Try to find the module by its exact name
        full_module_name =
          case module_name do
            name when byte_size(name) > 0 ->
              if String.ends_with?(name, "Handler") do
                "Xombadill.Handlers.#{name}"
              else
                "Xombadill.Handlers.#{name}Handler"
              end

            _ ->
              nil
          end

        if full_module_name do
          Task.start(fn -> ReloadCoordinator.reload_module(full_module_name, channel, client) end)
        else
          ExIRC.Client.msg(client, :privmsg, channel, "❌ Invalid module name format")
        end

      text == "!stop" ->
        ExIRC.Client.msg(client, :privmsg, channel, "Usage: !stop <module>")

      String.match?(text, ~r/^!stop\s+(\w+)$/) ->
        [_, module_name] = Regex.run(~r/^!stop\s+(\w+)$/, text)
        full_module_name = "Xombadill.Handlers.#{String.capitalize(module_name)}Handler"
        Task.start(fn -> ReloadCoordinator.stop_module(full_module_name, channel, client) end)

      text == "!start" ->
        ExIRC.Client.msg(client, :privmsg, channel, "Usage: !start <module>")

      String.match?(text, ~r/^!start\s+(\w+)$/) ->
        [_, module_name] = Regex.run(~r/^!start\s+(\w+)$/, text)
        full_module_name = "Xombadill.Handlers.#{String.capitalize(module_name)}Handler"
        Task.start(fn -> ReloadCoordinator.start_module(full_module_name, channel, client) end)

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
