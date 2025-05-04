defmodule Xombadill.TrackedPlayers do
  use Agent

  def start_link(initial_players) do
    Agent.start_link(fn -> MapSet.new(initial_players) end, name: __MODULE__)
  end

  def track(nick) do
    Agent.update(__MODULE__, &MapSet.put(&1, nick))
  end

  def untrack(nick) do
    Agent.update(__MODULE__, &MapSet.delete(&1, nick))
  end

  def list do
    Agent.get(__MODULE__, &MapSet.to_list/1)
  end

  def tracked?(nick) do
    Agent.get(__MODULE__, &MapSet.member?(&1, nick))
  end
end
