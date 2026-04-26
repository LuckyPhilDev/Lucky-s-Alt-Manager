# Lucky's Alt Manager

A toolkit of small quality-of-life features for leveling and managing alts.

## Features

- **Stat Priority Window** — A floating window showing your current spec's secondary stat priority (Crit, Haste, Mastery, Versatility) with colored relationship indicators. Saved per character so each alt can position and toggle it independently.
  - Hover the operators to see what they mean: equal, marginally better, clearly better, or much better.
  - Hides automatically for specs without data.
- **Customisable Stat Weights** — Override the default weight values for any spec via a dedicated dialog, useful if you prefer your own numbers or follow a guide that disagrees.
- **Quest Reward Spec Hints** — While leveling, overlays small spec icons on quest choice rewards to show which of your specs would prefer each item, scored against the stat priorities. Works with the default quest UI and DialogueUI.
- **Auto Accept & Hand In Quests** — Skips dialog clicks for routine quests. Pauses while Shift is held, skips Delver's Call quests, and skips quests with a reward choice so you can pick yours.
- **Skip Cinematics** — Automatically skips in-game cinematics and movies.
- **Delver's Call Tracker** — A floating window listing the ten weekly Delver's Call quests, marking each as available, in-progress, or done, with a progress bar and an estimate of XP earned and remaining.
- **Minimap Button** — Quick access to settings.

Most features support a "While Leveling" mode that turns them off automatically once you hit the level cap.

## Installation

Install from CurseForge. Lucky's Utils is required and will be installed automatically by the CurseForge app.

For manual installation, drop the `Lucky's Alt Manager` folder into `World of Warcraft/_retail_/Interface/AddOns/`. Lucky's Utils must also be installed.

## Usage

1. Log in. The minimap button and any enabled floating windows will appear.
2. Click the minimap button or type `/lam` to open settings.
3. Toggle features on, off, or only while leveling.
4. Drag any floating window to reposition. Positions are remembered.

## Slash Commands

| Command | Action |
|---|---|
| `/lam` | Open the settings panel |
| `/delvers` or `/dct` | Toggle the Delver's Call tracker window |
| `/dct reset` | Clear the saved per-quest XP value (re-probes on next quest update) |

## Settings

Open via the minimap button or **Game Menu → Options → AddOns → Lucky's Alt Manager**.

- **Windows** — Opacity slider for floating windows when your cursor is not over them; toggle for the Stat Priority window.
- **Quest Rewards** — Toggle for the spec hint overlays.
- **Quests** — Toggle for auto accept and hand in.
- **Cinematics** — Toggle for cinematic skipping.
- **Delver's Call** — Toggle for the tracker window.
- **Developer** — Debug logging.

A **Customise Stat Weights** button opens a dialog where you can override the per-spec stat weights used by the Stat Priority window and the Quest Reward hints.

## Author

Lucky Phil
