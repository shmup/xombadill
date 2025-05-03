defmodule Xombadill.ReloadCoordinator do
  @moduledoc """
  Handles the actual reloading logic, separate from handler code.
  This module is not intended to be reloaded.
  """
  require Logger

  def reload_module(module_name, channel, client) do
    Logger.info("Attempting to reload module: #{module_name}")

    try do
      module = String.to_existing_atom("Elixir." <> module_name)
      Xombadill.HandlerRegistry.unregister(module)

      :code.purge(module)
      :code.delete(module)

      file_path =
        module_name
        |> String.split(".")
        |> Enum.map(&Macro.underscore/1)
        |> Enum.join("/")
        |> (&("lib/" <> &1 <> ".ex")).()

      Code.compile_file(file_path)
      Xombadill.HandlerRegistry.register(module)

      ExIRC.Client.msg(client, :privmsg, channel, "✅ Module #{module_name} reloaded successfully")
    rescue
      e ->
        Logger.error("Failed to reload module #{module_name}: #{inspect(e)}")

        ExIRC.Client.msg(
          client,
          :privmsg,
          channel,
          "❌ Error reloading #{module_name}: #{inspect(e)}"
        )
    end
  end

  def reload_all_handlers(channel, client) do
    handlers = Xombadill.HandlerRegistry.list_handlers()

    Enum.each(handlers, fn module ->
      module_name = Atom.to_string(module) |> String.replace_prefix("Elixir.", "")
      reload_module(module_name, channel, client)
    end)

    ExIRC.Client.msg(client, :privmsg, channel, "✅ All handlers reloaded")
  end
end
