# AGENTS.md

Guidelines for AI agents working on this project.

## Project

Kiro is a GNOME terminal emulator written in **Vala** with GTK4 + LibAdwaita + VTE.
Build system: **Meson + Ninja**.

## Build

```bash
meson setup builddir
ninja -C builddir
```

## Source layout

```
src/main.vala      — Application entry point, actions, shortcuts
src/engine.vala    — VTE terminal engine (shell, colors, font, URL detection)
src/ui.vala        — MainWindow, TerminalTab, PreferencesDialog
src/settings.vala  — GSettings wrapper (28 keys)
data/              — GSchema, desktop file, appdata
po/                — Translations (en, ru)
```

## Key constraints

- **App ID**: `dev.anmitali.kiro` — do not change.
- **GSettings schema path**: `/dev/anmitali/kiro/` — must match the app ID prefix.
- **Minimum versions**: GTK 4.8, LibAdwaita 1.2, VTE 0.70, GLib 2.66, Vala 0.56.
- Target **GNOME HIG** — use `Adw.*` widgets over raw GTK equivalents where available.

## Deprecation rules

- Use `load_from_string()` — not `load_from_data()` (deprecated GTK 4.12).
- Use `Gtk.StyleContext.add_provider_for_display()` — not `widget.get_style_context()` (deprecated GTK 4.10).
- Use `Adw.AboutDialog` — not `Adw.AboutWindow` (deprecated ADW 1.6).
- Use `Adw.PreferencesDialog` — not `Adw.PreferencesWindow` (deprecated ADW 1.6).
- Use `Gtk.FontDialogButton` — not `Gtk.FontButton` (deprecated GTK 4.10).
- Use `Gtk.ColorDialogButton` — not `Gtk.ColorButton` (deprecated GTK 4.10).
- Use `Adw.StyleManager` for dark/light theme detection — not `StyleContext`.

## Changelog

After every change to source code or project files, **update `CHANGELOG.md`**:

1. Add an entry under `## [Unreleased]`.
2. Use the appropriate subsection: `Added`, `Changed`, `Fixed`, `Removed`, or `Security`.
3. Write one line per logical change — concise, in past tense.
4. Do **not** add entries for changes to `CHANGELOG.md` itself, `AGENTS.md`, or other meta files.

Example:
```markdown
## [Unreleased]

### Fixed
- Schema path corrected from `/kz/anmitali/kiro/` to `/dev/anmitali/kiro/`

### Changed
- Migrated from `Adw.AboutWindow` to `Adw.AboutDialog`
```

## Code style

- 4-space indentation, LF line endings, UTF-8.
- Follow existing patterns: signals over polling, settings via GSettings, no hardcoded strings (use `_()`).
