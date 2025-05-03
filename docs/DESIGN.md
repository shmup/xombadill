# Design: OCTOTROG Elixir Rewrite

## Overview
This bot monitors player activity and milestones for Dungeon Crawl Stone Soup (DCSS). It relays information, responds to commands, and manages a watchlist, primarily by interacting with IRC infobots and storing relevant data locally.

## Core Features
- **IRC Client**: Connects to specified servers/channels and listens for messages from DCSS bots.
- **Message Parsing**: Detects milestone, death, and game info via regex over IRC output.
- **Milestone/Death Logging**: Stores player milestones and deaths in a local SQL database.
- **Watchlist Management**: Track and notify on activity for a user-specified watchlist.
- **Command Relay**: Accepts commands (lookup, queries) and relays them to infobots, returning responses.
- **Web Interface**: (Optional) Show recent activity/challenges via HTTP.

## Main Processes
1. **IRC Interaction**
    - Connect to one or more IRC servers and channels.
    - Listen for lines from known DCSS bots (e.g., Sequell, Henzell, Gretell, etc.).
    - Parse messages using regex to extract game events and info.
    - Optionally, send commands to infobots (for extra info or relaying user commands).

2. **Database**
    - Use SQLite (or PostgreSQL) for local state:
        - `deaths` table (game over events)
        - `watchlist` table
        - `dictionary` table
        - `challenges` and challenge-related views
    - Insert parsed milestone/death events and watchlist changes.

3. **Watchlist**
    - Manage list of monitored player names.
    - When a watched player triggers an event (death, milestone), echo or relay it.
    - Provide commands for adding/removing from watchlist via IRC.

4. **Command Relaying**
    - Accept user messages beginning with command prefixes (e.g., !, ??, etc.)
    - Forward these to the appropriate infobot on IRC.
    - Relay responses back to the user/channel.

5. **Web (Optional)**
    - Serve a basic web page with recent games and challenges.
    - HTTP server (optional, can be added after core bot functions work).

## Tech Mapping for Elixir

- **IRC**: Use [hedwig](https://hexdocs.pm/hedwig/readme.html) or [ex_irc](https://hexdocs.pm/ex_irc/) for IRC client functionality.
- **Database**: Ecto + Sqlite or PostgreSQL.
- **Web (if needed)**: Plug/Phoenix.
- **Regex Parsing**: Native Elixir regex.
- **Bot/Command Architecture**: GenServer or Agent for stateful modules (e.g., watchers, relay logic).
- **Concurrency**: Leverage Supervisor tree, processes for each functional isolation (IRC handler, DB manager, etc).

## Modules/Responsibilities

1. **IRCClient**
    - Maintain IRC connections
    - Route incoming IRC messages to Parser/Handlers
    - Allow for outgoing messages/commands (both from user or for relay to infobots)

2. **Parser**
    - Given a message, match against regexes for known event formats
    - Convert matched messages into structured Elixir maps

3. **EventLogger**
    - Interface with DB
    - Insert/Update deaths, milestones, challenge state, etc.
    - Provide query interface for watchlist and recent events

4. **WatchlistManager**
    - Maintain watchlist state (from DB)
    - Commands for add/remove/show
    - Check if a player from a parsed event is on the watchlist

5. **CommandRelay**
    - Accept and recognize user commands (prefixes !, ??, etc.)
    - Forward matching lines to infobots, await and relay response

6. **ChallengeManager**
    - Track challenges (in DB/views)
    - Query for current/previous challenges and winner status

7. **HTTPServer** (optional/todo)
    - Expose endpoints for recent games, challenges

## Key Interactions
- When an IRC message from a DCSS bot matches a death/milestone regex and is for a watched player, log and announce it.
- When a user issues a supported command (!lg, ??, etc.), relay to the correct infobot and copy back the response.

## Minimal State
- IRC connections/channels
- Watchlist (list of strings)
- Persistent DB tables for deaths, watchlist, challenges, dictionary

## Regexp Coverage
- Milestone events
- Death events
- Morgue/ttyrec/url events
- Edge cases: parsing error and partial matches should be ignored or logged but not crash the bot.

## Extendability
- Make regex and event parsers modular/configurable
- Cleanly separate IRC, DB, and parsing/message logic

## Example Minimal Startup Flow
1. Connect to IRC, join channels
2. Load watchlist and connect to DB
3. Listen for IRC lines, parse, update DB and possibly relay message
4. Listen for commands (relaying or watchlist control)

---
This document is not code.
Use it to drive implementation of core Elixir modules and functional breakdown.

---

## Specific Table: DCSS Info/Relay Bots

The table below lists the IRC nicks and characteristics for all bots commonly used for relaying crawl game information, with relay and webtiles command prefixes. These are the bots we care about paying attention to:

| Bot Nick        | Short Name   | Server                | Command Prefix  | Watch Command  | Notes                                           |
| --------------- | ------------ | --------------------- | --------------- | -------------- | ----------------------------------------------- |
| Sequell         | sequell      | Multi-server/global   | !, ??, etc.     |                | Main stats bot, relays most queries/globals     |
| Cheibriados     | chei         | Multi-server/global   | %%              |                | Alternate stats/learnDB bot                     |
| Henzell         | cao          | crawl.akrasiac.org    | !               | !watch         | CAO server bot; server info/dumps/whereis       |
| Gretell         | cdo          | crawl.develz.org      | @               |                | CDO server bot; server info/dumps/whereis       |
| Sizzell         | cszo         | crawl.s-z.org         | %               | %watch         | CSZO server bot; server info/dumps/whereis      |
| Jorgrell        | cjr          | crawl.jorgrun.rocks   | =               | =watch         | CJR server bot; server info/dumps/whereis       |
| Lantell         | clan         | crawl.lantea.net      | $               | $watch         | CLAN server bot; server info/dumps/whereis      |
| Rotatell        | cbro         | crawl.berotato.org    | ^               | ^watch         | CBRO server bot; server info/dumps/whereis      |
| Rotatelljr      | cbro+        | crawl.berotato.org    | ^               |                | Alternate/secondary CBRO bot                    |
| Cbrotell        | cbr2         | crawl.berotato.org    |                 |                | Alternate/secondary CBRO bot (CBR2 etc)         |
| Cbrotelljr      | cbr2+        | crawl.berotato.org    |                 |                | Alternate/secondary CBRO bot (CBR2 etc)         |
| Eksell          | cxc          | cxc.hu (community)    |                 |                |                                                 | watch | CXC community crawl bot |
| Postquell       |              | Multi-server/global   | !, ??, etc.     |                | Alternate stats bot (Sequell backup)            |

**Legend**:
- *Command Prefix*: Prefix for server-specific info queries (!dump, @whereis, etc).
- *Watch Command*: The IRC command prefix for requesting webtiles watch URLs (when supported).
- Not all bots support all commands; see specific server's bot help for details.

Focus specifically on Henzell, Sequell, and any bots directly used for monitoring deaths/milestones (see above).
