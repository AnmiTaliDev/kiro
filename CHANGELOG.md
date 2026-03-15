# Changelog

All notable changes to Kiro are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Changed
- Migrated from `Adw.AboutWindow` to `Adw.AboutDialog` (ADW 1.6+)
- Migrated from `Adw.PreferencesWindow` to `Adw.PreferencesDialog` (ADW 1.6+)
- Migrated from `Gtk.FontButton` to `Gtk.FontDialogButton` (GTK 4.10+)
- Migrated from `Gtk.ColorButton` to `Gtk.ColorDialogButton` (GTK 4.10+)
- Replaced deprecated `CssProvider.load_from_data()` with `load_from_string()`
- Replaced deprecated `StyleContext.add_provider()` with `add_provider_for_display()`
- Replaced deprecated `Vte.Terminal.set_encoding()` — UTF-8 is default in modern VTE
- Replaced deprecated `Vte.Terminal.rewrap_on_resize` — handled automatically
- Theme color detection now uses `Adw.StyleManager` instead of deprecated `StyleContext`
- `urgent-bell` and `mouse-autohide` settings now apply at runtime without re-setup

### Fixed
- GSettings schema path was `/kz/anmitali/kiro/` — corrected to `/dev/anmitali/kiro/`
- Redundant `match_check()` double call in URL click handler
- `setup_terminal()` was incorrectly called on every settings change for some keys,
  which duplicated event controllers on each change
- `urgent-bell` toggle from Preferences had no effect (signal only connected at init)
- Unused `pty` field removed from `TerminalEngine`

## [1.0.0] - 2025-07-28

### Added
- Initial release
- Tabbed terminal interface via `Adw.TabView`
- Full VTE terminal emulation with UTF-8 support
- Customizable font, colors, cursor, scrollback
- System theme color integration
- Background transparency support
- URL and file path detection with click-to-open
- Drag-and-drop file path insertion
- Context menu (copy, paste, select all)
- Keyboard shortcuts for all common actions
- Preferences dialog with General, Appearance, Behavior, Advanced pages
- Window size and state persistence
- English and Russian translations
- GSettings-based configuration (28 keys)
