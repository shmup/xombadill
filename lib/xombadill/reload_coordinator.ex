defmodule Xombadill.ReloadCoordinator do
  @moduledoc """
  Handles the actual reloading logic, separate from handler code.
  This module is not intended to be reloaded.
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
end
