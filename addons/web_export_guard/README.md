# Web Export Guard

A small **Godot 4.x editor plugin** (GDScript). It is a dock, not a game.

The plugin is **FREE / MIT**. Intended for [store.godotengine.org](https://store.godotengine.org/).

Independent helper. Not affiliated with, endorsed by, or sponsored by Godot Engine.

## How to enable in a Godot 4.x project

1. Copy `addons/web_export_guard/` into your Godot 4.x project as `res://addons/web_export_guard/`.
2. Project → Project Settings → Plugins.
3. Enable **Web Export Guard**.
4. A dock named Web Export Guard appears (right side by default). Click Refresh after you change export presets or export.

Disable the plugin from the same Plugins list. The dock is removed when the plugin is turned off.

## What it checks

For each export preset whose `platform` is `Web` (case-insensitive) in `res://export_presets.cfg`:

- **Filename.** The `export_path` file name should be `index.html` or `index.htm`. Godot 4's web export docs suggest `index.html` so hosts that serve a directory still find the page.
- **Last export siblings.** If that HTML file exists on disk, the dock looks next to it for the same basename plus `.wasm`, `.js`, and `.pck`. Those are the three files the official web export page describes as traveling with the HTML.
- **No export yet.** If the HTML path is set but the file is not on disk, the dock says **no export on disk yet**. It does not treat missing siblings as a failure in that case.
- **No Web preset.** If the project has no Web preset, the dock says so and points you to **Project → Export**.
- **Open folder.** One button per Web preset runs `OS.shell_open` on the globalized parent directory. The button is disabled when the export path is empty. The plugin does not create the folder; if the directory is missing, it says so.

Refresh runs when you click the button and again when the dock becomes visible.

## What it does not do

- It does not export the project, write `export_presets.cfg`, or install export templates.
- It does not lint a zip, check MIME types, or tell you which HTTP headers a host must send (no COOP/COEP / SharedArrayBuffer advice).
- It does not upload to itch.io or any other host.
- It does not replace the official Godot web export documentation.
- It is not a runtime node. Checks run in the editor dock only.
- It does not ship a Godot logo or claim any official status.

## After you export (eyeball)

The dock only checks the preset path and siblings on disk. After Godot finishes a Web export, a short second pass with your own eyes:

- The file you exported is named `index.html` (or `index.htm`), not the project title.
- The matching `.wasm`, `.js`, and `.pck` sit next to it — same stem as the HTML.
- Do not rename those files after export. Godot 4 expects the set to keep the name it wrote.
- Upload the export folder, not the Godot project root.
- If you zip the folder, put the HTML at the zip root (or wherever your host says the start file must live).
- Note the Godot version that produced this export so a later template mismatch is easier to spot.

## Changelog

- **0.1.1** — Fix Godot 4.4 typed GDScript load failure in `dock.gd` (`PackedStringArray` for sibling extensions).

## License

MIT. Copyright 2026 Brandon Smith. See `LICENSE`.

Plugin GDScript, documentation, and the store thumbnail/icon were created by AI.
