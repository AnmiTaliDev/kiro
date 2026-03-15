# Contributing to Kiro

Thanks for your interest in contributing. Here's everything you need to get started.

## Before You Start

- Check [open issues](https://github.com/AnmiTaliDev/kiro/issues) to avoid duplicate work
- For big changes, open an issue first to discuss the idea
- For small fixes (typos, obvious bugs) — just send a PR

## Setting Up

```bash
git clone https://github.com/AnmiTaliDev/kiro.git
cd kiro
meson setup builddir --buildtype=debug
meson compile -C builddir
./builddir/src/kiro
```

## Code Style

- Language: **Vala**
- Follow the style of the surrounding code
- Keep methods focused and short
- No trailing whitespace

## Submitting a PR

1. Fork the repo and create a branch: `git checkout -b my-feature`
2. Make your changes
3. Build and test manually: `meson compile -C builddir && ./builddir/src/kiro`
4. Commit with a clear message
5. Open a pull request against `main`

## Adding a Translation

1. Add your language code to `po/LINGUAS`
2. Copy the template: `cp po/en.po po/YOUR_LANG.po`
3. Fill in the translations in your `.po` file
4. Test it: `LANG=YOUR_LANG ./builddir/src/kiro`

## Reporting Bugs

Open an issue and include:
- What you did
- What you expected
- What actually happened
- OS, GTK version, VTE version

## Questions

Use [GitHub Discussions](https://github.com/AnmiTaliDev/kiro/discussions).
