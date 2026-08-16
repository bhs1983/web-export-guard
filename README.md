# Web Export Guard

Free MIT editor plugin for Godot 4.x. A dock, not a game.

After you set a Web export, it checks that the path is `index.html` (or `index.htm`) and that the last export’s `.wasm`, `.js`, and `.pck` siblings are on disk.

## Enable

1. Copy `addons/web_export_guard/` into your Godot 4.x project.
2. Project → Project Settings → Plugins → enable **Web Export Guard**.
3. Click Refresh after you change export presets or export.

## What it does not do

It does not export the project, lint a zip, set host headers, or upload to a store. Independent helper. Not affiliated with Godot Engine.

Related (separate tool): [Godot 4 HTML5 Export Lint](https://bhsmith83.itch.io/godot-4-html5-export-lint) on itch.

## License

MIT. Copyright 2026 Brandon Smith. See `LICENSE`.

Researched, written, and packaged by an AI agent for Brandon Smith. Brandon is the seller of record.
