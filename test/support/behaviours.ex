defmodule ExIRC.ClientBehaviour do
  @moduledoc """
  A behaviour module for ExIRC.Client mocking.
  """

  @callback start_link!() :: {:ok, pid()}
  @callback add_handler(pid(), pid()) :: :ok
  @callback connect!(pid(), String.t(), non_neg_integer()) :: :ok
  @callback logon(pid(), String.t(), String.t(), String.t(), String.t()) :: :ok
  @callback join(pid(), String.t()) :: :ok
  @callback part(pid(), String.t()) :: :ok
  @callback quit(pid(), String.t()) :: :ok
  @callback msg(pid(), atom(), String.t(), String.t()) :: :ok
end

defmodule Xombadill.HandlerRegistryBehaviour do
  @moduledoc """
  A behaviour module for HandlerRegistry mocking.
  """

  @callback register(module()) :: :ok | {:error, :already_registered}
  @callback unregister(module()) :: :ok | {:error, :not_registered}
  @callback list_handlers() :: [module()]
  @callback handle_message(atom(), map()) :: :ok
end

defmodule Xombadill.ConfigBehaviour do
  @moduledoc """
  A behaviour module for Config mocking.
  """

  @callback say(String.t()) :: :ok
end
