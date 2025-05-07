defmodule Xombadill.Handlers.LearnDBHandler do
  @moduledoc """
  A stub/example handler that would, in a full implementation, handle lookups in a learn database.

  Currently, this module does nothing, but shows the basic handler API in use.
  """
  @behaviour Xombadill.HandlerBehaviour
  require Logger

  def handle_message(_type, _message), do: :ok
end
