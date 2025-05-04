defmodule Xombadill.Handlers.MilestoneHandler do
  @moduledoc """
  A simple example handler that echoes messages back to the channel.
  """
  @behaviour Xombadill.HandlerBehaviour
  require Logger

  def handle_message(_type, _message), do: :ok
end
