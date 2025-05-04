# Xombadill

Xombadill is a bot for relaying and tracking Dungeon Crawl Stone Soup (DCSS) player milestones, deaths, and events by interacting with IRC infobots (like Sequell, Henzell, etc). It watches for specific messages on IRC channels and can maintain a watchlist of player names, echoing information as needed. Xombadill is designed to be modular and extensible, making it easy to add new handler modules for different event logic.

[![Elixir CI](https://github.com/shmup/xombadill/actions/workflows/elixir.yml/badge.svg)](https://github.com/shmup/xombadill/actions)


## Features

- **IRC Event Listener**: Connects to IRC servers/channels, watches for DCSS info bots, parses death/milestone/game events.
- **Command Relay**: Accepts `!` and other command prefixes, relays to bot, and echoes output.
- **Player Watchlist**: Track and notify on activity for a list of player(s). `!watch`, `!unwatch`, `!watched` commands.
- **Handler Modules**: Add pluggable handler modules that each get notified of IRC events (`channel_message`, `user_joined`, etc).
- **Live Handler (Re)loading**: Reload handler modules at runtime via `!reload` and `!stop`/`!start`.
- **Extensible**: Easily add modules for new milestones, web UI, or DB integration.
- **Logger Configuration**: Adjustable log level via chat command.
- **Basic Tests**: Simple ExUnit/Mox testing for major components.


## Running

1. **Install dependencies:**
   ```bash
   mix deps.get
   ```

2. **Start the bot:**
   ```bash
   mix run --no-halt
   ```

   Optionally, use IEx for a shell:
   ```bash
   iex -S mix
   ```

3. **Configure connections:**
   The IRC server/channel/nick values can be changed in `lib/xombadill/application.ex` under `config`.

4. **Develop:**
   - All handler modules are in `lib/xombadill/handlers/`.
   - Use `!reload Mod` to hot-reload, or update `default_handlers:` in Application for startup loading.
   - Test by running `mix test` or with [mix test.watch](https://github.com/lpil/mix-test.watch).


## Usage

By default Xombadill will:

- Join IRC server(s) and channel(s) defined in config
- Listen for public messages and relay messages to registered handler modules
- Handler modules can watch for milestone/death patterns, relay commands, echo or filter messages, manage a player watchlist, and more
- Users on IRC can:
    - `!watch <nick>` to add a player to the tracked list
    - `!unwatch <nick>` to remove
    - `!watched` to see list
    - `!reload` or `!reload Handler` and `!start`/`!stop <Handler>` to (re)load and tweak handlers
    - `!loglevel info|debug|warning|error` to set the logging verbosity


## Key Modules
- `Xombadill.IrcClient`: IRC connection, message dispatch, joins, etc
- `Xombadill.HandlerRegistry`: Keeps a list of handler modules and calls `handle_message/2` on each one
- `Xombadill.HandlerBehaviour`: Behaviour contract for a handler module
- `lib/xombadill/handlers/*_handler.ex`: Example handlers: EchoHandler, MilestoneHandler, RelayHandler, etc
- `Xombadill.Config`: Shared config, also used to relay a chat message back to the irc network
- `Xombadill.ReloadCoordinator`: Responsible for module hot-reloading (`!reload` command, etc)
- `Xombadill.TrackedPlayers`: Watchlist, managed via `!watch`, `!unwatch`, and `!watched` commands


## Adding Handlers

Add a new file in `lib/xombadill/handlers/new_event_handler.ex`:
```elixir
defmodule Xombadill.Handlers.NewEventHandler do
  @behaviour Xombadill.HandlerBehaviour
  require Logger

  @impl true
  def handle_message(:channel_message, %{text: text, ...} = msg) do
    # Do something with the channel message...
    :ok
  end

  def handle_message(_type, _message), do: :ok
end
```
Then register with `Xombadill.HandlerRegistry.register(Xombadill.Handlers.NewEventHandler)` or add to the `default_handlers:` list in the supervisor for automatic loading on boot.

Handlers will be called on every IRC message/event (public, privmsg, join/quit, etc) with their `type` and a standardized `message` map.


## Configuration

Edit the IRC servers/channels/nick in `lib/xombadill/application.ex` under the `config` map.

You can change the default channel and server in the `Xombadill.Config` module, or call with the full signature:

```elixir
Xombadill.IrcClient.say(:libera, "#crawl-octolog", "Hello world!")
```

Other options:
- Logging can be tuned with `!loglevel debug`, etc (see Logger docs)
- Handlers can be (re)loaded/replaced with `!reload Handler` command over IRC


## Development & Testing

- Format code: `mix format`
- Run tests: `mix test`
- Live test run: `mix test.watch` (after `mix deps.get` pulls in test watcher)
- Handlers support hot code reload (`!reload <Mod>` in irc)
- Read [docs/DESIGN.md](docs/DESIGN.md) for additional design and mapping details


## Project Structure

```
xombadill/
  lib/
    xombadill/
      application.ex
      config.ex
      handler_behaviour.ex
      handler_registry.ex
      irc_client.ex
      irc_supervisor.ex
      reload_coordinator.ex
      tracked_players.ex
      handlers/
        echo_handler.ex
        learndb_handler.ex
        milestone_handler.ex
        player_tracker_handler.ex
        relay_handler.ex
        reload_handler.ex
  docs/      # design, primer, tables, etc
  test/      # ExUnit, Mox, mocks for handler registry
  deps/      # exirc, file_system, mix_test_watch, mox, ...
  config/
    config.exs
  mix.exs, mix.lock, justfile
  README.md
```


## Contributions
- Issues and PRs are welcome!
- For larger ideas, open a discussion or an issue first.
- Please run `mix format` and `mix test` before submitting a PR.
- Add or update handler documentation as appropriate.


## License

MIT (see LICENSE or relevant dependency licenses)
