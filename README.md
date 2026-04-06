# CharacterMountFavorites

`CharacterMountFavorites` is a Retail World of Warcraft addon that gives each character its own mount favorites list without changing Blizzard's account-wide favorites.

## Features

- Per-character mount favorites
- Separate `Character Favorite` toggle in the Mount Journal
- Random summon from this character's favorites
- Fallback options when a character has no favorites
- Smart usable-mount selection for current conditions
- Dedicated favorites manager window
- Settings panel
- Tooltip support
- Minimap button
- Drag-to-action-bar summon shortcut

## Why This Addon Exists

Blizzard mount favorites are account-wide. This addon keeps a separate favorites list for each character, so one character's mount setup does not affect another.

## Retail Support

Built for current Retail WoW.

## Installation

1. Download or clone this repository.
2. Place the `CharacterMountFavorites` folder into:

```text
World of Warcraft\_retail_\Interface\AddOns\
```

3. Restart WoW or reload your UI.
4. Make sure `CharacterMountFavorites` is enabled from the addon list.

## How To Use

### Settings Panel

Open:

```text
Game Menu -> Options -> AddOns -> Character Mount Favorites
```

From there you can:

- enable or disable the addon
- show or hide the minimap button
- show or hide the Mount Journal marker
- enable or disable tooltip support
- configure fallback summon behavior
- open the favorites manager
- clear favorites for the current character

### Favorites Manager

The manager lets you:

- browse collected mounts
- search mounts
- filter by mount type
- sort entries
- mark or unmark `Character Favorite`

### Mount Journal

The addon adds a separate `Character Favorite` control that does not change Blizzard's built-in favorite system.

### Action Bar Shortcut

The summon icon can be dragged to a default action bar.

Because WoW action bars only accept protected action types, the dragged shortcut is created as a small macro-backed action that runs the addon's summon logic.

## SavedVariables

The addon stores data in:

```lua
CharacterMountFavoritesDB
```

Favorites are stored per character using a structure like:

```lua
CharacterMountFavoritesDB = {
  global = {
    settings = { ... },
    minimap = { ... },
  },
  characters = {
    ["Realm - Character"] = {
      favorites = {
        [mountID] = true,
      },
    },
  },
}
```

## Notes

- Blizzard account-wide favorites are never overwritten by this addon.
- If Blizzard changes Mount Journal UI internals in a future patch, journal integration may need a small update.

## Changelog

See [CHANGELOG.md](CHANGELOG.md).
