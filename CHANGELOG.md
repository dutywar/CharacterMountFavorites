# Changelog

All notable changes to `CharacterMountFavorites` will be documented in this file.

## [1.0.0] - 2026-04-06

### Added
- Initial Retail WoW addon release.
- Per-character mount favorites stored separately from Blizzard account-wide favorites.
- Mount Journal integration with a separate `Character Favorite` toggle.
- Random summon for character favorites with fallback behavior options.
- Smart summon filtering for usable mounts in the current environment.
- Dedicated favorites manager window with search, sorting, and filters.
- Settings panel with general, summon behavior, and mount management options.
- Tooltip support showing whether a mount is a character favorite.
- Minimap button support.
- Action-bar shortcut support through the summon icon.

### Changed
- Updated summon icon texture to WoW icon `413588`.
- Reworked the settings panel layout for cleaner spacing and readability.
- Simplified the favorites manager list to `Name`, `Type`, and `Favorite`.
- Restyled the summon icon to better match the addon UI.

### Fixed
- Fixed character mount type detection so Ground, Flying, Aquatic, and Dragonriding/Skyriding filters work.
- Fixed favorites manager footer overlap and general layout issues.
- Fixed the floating `Favorite` header appearing in the middle of the manager.
- Fixed stray visible text leaking from favorite toggle controls.
- Fixed summon icon drag behavior for action-bar shortcut creation.
