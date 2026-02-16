# smart-rename

A tiny yet powerful CLI file renaming tool.

This script behaves like a safer, interactive and portable version of `rename` + `mv`.

It works on any system with PHP CLI installed and provides batch renaming, preview mode, interactive confirmations, overwrite control and automatic single-file rename detection.

---

## Features

- Glob pattern renaming (`*.md`, `file-*`, etc)
- Regex search mode
- Interactive confirmation (per file)
- Dry-run preview (`--pretend`)
- Safe by default (never overwrites unless allowed)
- Replace mode (`--replace`)
- Force mode (`--force`, like `mv -f`)
- Single file rename (automatic mv-like behavior)
- Recursive directory traversal
- Positional OR named arguments

---

## Requirements

- PHP 8.0 or newer
- CLI access

Check:

```sh
php -v
