defmodule Xombadill.HandlerBehaviour do
  @moduledoc """
  Behaviour for IRC message handlers.
  """

  @doc """
  Handle an IRC message.

  The type can be one of:
  - :channel_message - Message sent to a channel
  - :private_message - Private message sent to the bot
  - :user_joined - User joined a channel
  - :user_left - User left a channel
  - :user_quit - User quit the server
  - :nick_changed - User changed their nick
  """
  @callback handle_message(type :: atom(), message :: map()) :: any()
end
