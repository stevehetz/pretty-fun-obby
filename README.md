# Pretty Fun Obby

**[▶ Play it on Roblox](https://www.roblox.com/games/139398903012255/Pretty-Fun-Obby)**

<p>
  <img src="docs/images/subway-castle.png" alt="A player stands on a stage below floating subway cars, with a castle and a colorful path of platforms behind them" width="100%">
</p>
<p>
  <img src="docs/images/playground.png" alt="A playground-themed stage with slides, swings and floating platforms over blue water" width="49%">
  <img src="docs/images/trashcan.png" alt="A player holds the throwable trashcan tool above their head next to an enemy" width="49%">
</p>

A multi-world Roblox obby (obstacle course) game, built as a side project. Players climb through numbered stages, collect coins, earn skips, rebirth, and travel between four worlds. The game also has pets, trails, throwable tools, a VIP perk, enemies, a shop with gamepasses and developer products, and global leaderboards.

The game is written in Luau (Roblox's typed Lua) and developed outside Roblox Studio, in VS Code with Rojo, Git and StyLua. This repository holds the game's **scripts only**. Maps, stages, GUIs and models live in the Roblox place files and get synced together with this code through [Rojo](https://rojo.space).

## Highlights

- **One codebase, four places.** All four worlds are separate Roblox places that run the same code. Each place works out which world it is from its place ID, and players are teleported between worlds with their progress kept.
- **Modules load themselves.** A small loader finds every module in the server's `Services/` folder and the client's `Controllers/` folder and starts it. There are 23 services and 19 controllers, and adding a system takes no wiring.
- **Typed, reducer-style player state.** Save data has a Luau type. Changes are typed action objects passed to a single reducer, so every change to a player's state goes through one place.
- **Persistent data.** Player saves use ProfileService (session locking, auto-save). A global data service keeps the cross-server leaderboards.
- **Monetization.** Gamepasses, developer products, a subscription, donations and an in-game coin shop all come from one store config.
- **Clear client/server split.** The server owns and saves player state, and clients talk to it through RemoteEvents.

## Tooling

| Tool | Purpose |
| --- | --- |
| [Aftman](https://github.com/LPGhatguy/aftman) | Toolchain manager (pins the Rojo version in `aftman.toml`) |
| [Rojo](https://rojo.space) `7.4.4` | Syncs `src/` into Roblox Studio |
| [StyLua](https://github.com/JohnnyMorganz/StyLua) | Formatter (format-on-save is on in `.vscode/settings.json`) |

## Getting started

1. Install Aftman, then install the pinned tools:
   ```sh
   aftman install
   ```
2. Install the Rojo plugin in Roblox Studio (`rojo plugin install`, or get it from the Creator Store).
3. Start the sync server from the repo root:
   ```sh
   rojo serve
   ```
4. Open the world's place in Studio and click **Connect** in the Rojo plugin.

Every Rojo-managed service uses `$ignoreUnknownInstances`, so instances that exist only in the place file (stages, `Remotes`, GUIs, models) stay in place when you sync.

## Worlds

Each world is a separate Roblox place inside the same experience. The worlds are listed in [`Configs/Worlds.lua`](src/ReplicatedStorage/Configs/Worlds.lua):

| Name | Display name | Place ID |
| --- | --- | --- |
| World1 | World 1 | 139398903012255 |
| World2 | World 2 | 71122824760185 |
| World3 | World 3 | 128199095645816 |
| World4 | World 4 | 76460924671569 |

All places share the same codebase. Code that applies to only one world checks `WorldsConfig.IsWorld(...)` / `GetCurrentWorldName()`, or lives under a `Worlds/<WorldName>/Stages/<n>/` folder (for example, the conveyors and trampoline in World 2).

## Project structure

```
src/
├── ReplicatedStorage/        # Shared between server and client
│   ├── Configs/              # Badges, Settings, Sounds, Stages, Trails, Worlds
│   ├── Functions/            # Pure helpers (e.g. UpdateState reducer)
│   ├── Libs/                 # ModuleLoader, ViewportHelper
│   ├── Utils/                # BoundaryUtil, EnemyUtil
│   └── PlayerData.lua        # PlayerData type + default save data
├── ServerScriptService/
│   ├── Loader.server.lua     # Boots every module in Services/
│   ├── Services/             # Server-side game systems
│   ├── Scripts/              # Standalone server scripts (conveyors, enemies)
│   ├── Worlds/               # Per-world, per-stage server scripts
│   └── Libs/ProfileService.lua
├── ServerStorage/
│   └── Configs/Store.lua     # Gamepasses, dev products, store items
└── StarterPlayer/
    ├── StarterPlayerScripts/
    │   ├── Loader.client.lua # Boots every module in Controllers/
    │   ├── Controllers/      # Client-side systems
    │   │   └── Guis/         # One controller per GUI screen
    │   └── Worlds/           # Per-world, per-stage client scripts
    └── StarterCharacterScripts/
scripts/
└── rigger.lua                # Studio helper for rigging pet models (not synced)
```

## Architecture

### Services and controllers

The server and the client each run a single loader script that calls [`ModuleLoader`](src/ReplicatedStorage/Libs/ModuleLoader.lua):

- **Server:** requires every `ModuleScript` under `ServerScriptService/Services`.
- **Client:** requires every `ModuleScript` under `PlayerScripts/Controllers`, and any module added there later.

When a module exports `OnStart`, the loader runs it in its own thread with `task.spawn`. Modules follow this layout:

```lua
local Local = {}   -- private helpers
local Shared = {}  -- public API, returned to other modules

function Shared.OnStart()
	-- connect remotes, player events, etc.
end

return Shared
```

To add a system, create `FooService.lua` in `Services/` or `FooController.lua` in `Controllers/` and give it an `OnStart`. The loader picks it up automatically.

### Player data

- Data is saved with [ProfileService](src/ServerScriptService/Libs/ProfileService.lua) through [`PlayerDataService`](src/ServerScriptService/Services/PlayerDataService.lua).
- The data shape and its defaults live in [`PlayerData.lua`](src/ReplicatedStorage/PlayerData.lua). When you add a field, add it to both the `PlayerData` type and `DEFAULT_PLAYER_DATA`.
- State changes go through action objects (`{ type = "UpdateCoinCount", value = 100 }`) passed to `PlayerDataService.UpdateState`. The reducer in [`Functions/UpdateState.lua`](src/ReplicatedStorage/Functions/UpdateState.lua) handles them. To add a new kind of change, add a new action type to `UpdateStateAction` and handle it there.
- The client keeps a copy of the state through `StateController`.

### Remotes

Remote events live in a `Remotes` folder in `ReplicatedStorage`. Most of them are defined in the place file. [`CreateRemotes.server.lua`](src/ServerScriptService/CreateRemotes.server.lua) creates the rest at runtime.

### Store

Gamepasses, developer products and other store items are configured in [`ServerStorage/Configs/Store.lua`](src/ServerStorage/Configs/Store.lua) and handled by `StoreService` and `DonationService`. Items that cost coins are defined in `CoinService`.

## Rigging a pet model

[`scripts/rigger.lua`](scripts/rigger.lua) turns a model into a pet that can follow the player. The steps are at the top of the file: copy the script into the pet model, run the game, copy the rigged model, stop the game, and paste the model back into the workspace.
