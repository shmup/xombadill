defmodule Xombadill.ReloadCoordinator do
  @moduledoc """
  Encapsulates the logic for hot-reloading handler modules at runtime.
  Provides support functions for reloading, stopping, and starting handler modules via
  ReloadHandler commands, and manages messaging back to IRC clients on success/failure.

  This module itself is not hot-reloaded; it's relied on by the reload handler logic.
  """
  require Logger

  # In your ReloadCoordinator module:
  def reload_module(module_name, channel, client) do
    Logger.info("Attempting to reload module: #{module_name}")

    try do
      module = String.to_existing_atom("Elixir." <> module_name)
      Xombadill.HandlerRegistry.unregister(module)

      # Temporarily disable redefinition warnings
      previous_options = Code.compiler_options(ignore_module_conflict: true)

      :code.purge(module)
      :code.delete(module)

      file_path =
        module_name
        |> String.split(".")
        |> Enum.map(&Macro.underscore/1)
        |> Enum.join("/")
        |> (&("lib/" <> &1 <> ".ex")).()

      Code.compile_file(file_path)

      # Restore previous compiler options
      Code.compiler_options(previous_options)

      Xombadill.HandlerRegistry.register(module)

      Xombadill.Config.say("✅ Module #{module_name} reloaded successfully")
    rescue
      e ->
        Logger.error("Failed to reload module #{module_name}: #{inspect(e)}")

        # Handle both actual ExIRC.Client and mock client implementations
        try do
          cond do
            is_atom(client) ->
              # Handle case where client is a module that implements msg/4
              apply(client, :msg, [
                client,
                :privmsg,
                channel,
                "❌ Error reloading #{module_name}: #{inspect(e)}"
              ])

            true ->
              # Default to ExIRC.Client for regular clients
              ExIRC.Client.msg(
                client,
                :privmsg,
                channel,
                "❌ Error reloading #{module_name}: #{inspect(e)}"
              )
          end
        rescue
          err -> Logger.error("Error sending error message: #{inspect(err)}")
        end
    end
  end

  def reload_all_handlers(channel, client) do
    handlers = Xombadill.HandlerRegistry.list_handlers()

    Enum.each(handlers, fn module ->
      module_name = Atom.to_string(module) |> String.replace_prefix("Elixir.", "")
      reload_module(module_name, channel, client)
    end)

    Xombadill.Config.say("✅ All handlers reloaded")
  end

  def stop_module(module_name, channel, client) do
    Logger.info("Attempting to stop module: #{module_name}")

    try do
      module = String.to_existing_atom("Elixir." <> module_name)
      Xombadill.HandlerRegistry.unregister(module)
      Xombadill.Config.say("✅ Module #{module_name} stopped")
    rescue
      e ->
        Logger.error("Failed to stop module #{module_name}: #{inspect(e)}")

        ExIRC.Client.msg(
          client,
          :privmsg,
          channel,
          "❌ Error stopping #{module_name}: #{inspect(e)}"
        )
    end
  end

  def start_module(module_name, channel, client) do
    Logger.info("Attempting to start module: #{module_name}")

    try do
      module = String.to_existing_atom("Elixir." <> module_name)
      Xombadill.HandlerRegistry.register(module)
      Xombadill.Config.say("✅ Module #{module_name} started")
    rescue
      e ->
        Logger.error("Failed to start module #{module_name}: #{inspect(e)}")

        ExIRC.Client.msg(
          client,
          :privmsg,
          channel,
          "❌ Error starting #{module_name}: #{inspect(e)}"
        )
    end
  end
end
