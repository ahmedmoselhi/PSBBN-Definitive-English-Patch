#!/usr/bin/env python3

"""
Game Selector form the PSBBN Definitive Project
Copyright (C) 2024-2026 CosmicScale

<https://github.com/CosmicScale/PSBBN-Definitive-Project>

SPDX-License-Identifier: GPL-3.0-or-later

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
"""

import sys
import argparse
from pathlib import Path

from textual.app import App, ComposeResult
from textual.widgets import SelectionList, Button, Header, Footer, Static
from textual.widgets._selection_list import Selection
from textual.containers import Horizontal, Vertical
from textual import on


# ---------------- LANGUAGE LOADER ----------------

def load_language(lang: str) -> dict[str, str]:
    lang_file = Path(f"./scripts/assets/lang/{lang}.txt")

    if not lang_file.is_file():
        raise FileNotFoundError(f"Language file not found: {lang_file}")

    strings = {}

    for line in lang_file.read_text(encoding="utf-8").splitlines():
        line = line.strip()

        if not line or "=" not in line:
            continue

        key, value = line.split("=", 1)
        strings[key.strip()] = value.strip()

    return strings


class GameSelector(App[None]):
    TITLE = "Game Selector"
    """Interactive game selector with language-aware titles."""

    CSS = """
    #layout {
        height: 1fr;
    }

    #game_list {
        height: 1fr;
    }

    #status {
        padding: 0 1;
    }

    #progress_label {
        padding: 0 1;
        text-align: center;
        margin-top: 1;
        margin-bottom: 1;
    }

    #bottom {
        dock: bottom;
        height: auto;
        padding: 0 1;
    }

    #controls {
        width: 1fr;
        align: right middle;
    }

    #bulk_controls {
        width: 1fr;
        align: left middle;
    }

    #controls Button,
    #bulk_controls Button {
        margin-left: 1;
        margin-right: 1;
    }

    Horizontal {
        height: auto;
    }
    """

    def __init__(
        self,
        list_file: str,
        max_games: int,
        lang: str = "eng",
        exclude_file: str | None = None,
    ) -> None:
        super().__init__()
        self.list_file = Path(list_file)
        self.max_games = max_games
        self.lang = lang.lower()

        self.exclude_file = Path(exclude_file) if exclude_file else None
        self.excluded: set[str] = set()

        self.games: list[tuple[str, str]] = []

        # -------- LANGUAGE INIT --------
        self.lang_strings = load_language(self.lang)

        self._load_games()
        self._load_excluded()

        # set runtime title (replaces static TITLE usage)
        self.title = self.tr("GAME_SELECTOR_1")

    # ---------------- TRANSLATION ----------------

    def tr(self, key: str) -> str:
        return self.lang_strings.get(key, key)

    # ---------------- DATA LOADING ----------------

    def _load_games(self) -> None:
        if not self.list_file.is_file():
            print(f"Error: File not found: {self.list_file}", file=sys.stderr)
            sys.exit(1)

        for line in self.list_file.read_text(encoding="utf-8").splitlines():
            line = line.strip()
            if not line:
                continue

            parts = line.split("|")

            if len(parts) >= 5:
                fallback_title = parts[0]
                game_id = parts[1]
                game_type = parts[3]

                if self.lang == "jpn":
                    title = parts[5].strip() if len(parts) > 5 and parts[5].strip() else fallback_title
                else:
                    title = fallback_title

                display = f"{title} ({game_id})"
                self.games.append((display, line))
            else:
                self.games.append((line, line))

    def _load_excluded(self) -> None:
        if not self.exclude_file or not self.exclude_file.is_file():
            return

        for line in self.exclude_file.read_text(encoding="utf-8").splitlines():
            line = line.strip()
            if line:
                self.excluded.add(line)

    # ---------------- UI ----------------

    def compose(self) -> ComposeResult:
        yield Header()

        yield Static(
            "\n"
            f" {self.tr('GAME_SELECTOR_2')}\n"
            f" {self.tr('GAME_SELECTOR_3')}\n"
            f" {self.tr('GAME_SELECTOR_4')}"
            "\n",
            id="top_info"
        )

        yield Static(f"{self.tr('GAME_SELECTOR_5')} {len(self.games)}", id="status")

        with Vertical(id="layout"):
            self.list_widget = SelectionList[int](id="game_list")

            for idx, (display, _) in enumerate(self.games):
                self.list_widget.add_option(Selection(display, idx))

            yield self.list_widget

            yield Static("", id="progress_label")

            with Horizontal(id="bottom"):

                with Horizontal(id="bulk_controls"):
                    yield Button(self.tr("GAME_SELECTOR_7"), id="select_all")
                    yield Button(self.tr("GAME_SELECTOR_8"), id="select_none")

                with Horizontal(id="controls"):
                    yield Button(self.tr("GAME_SELECTOR_9"), id="confirm", variant="primary")

        yield Footer()

    # ---------------- LIFECYCLE ----------------

    def on_mount(self) -> None:
        sl = self.query_one("#game_list", SelectionList)

        # Start with EVERYTHING selected
        for idx in range(len(self.games)):
            sl.select(idx)

        # Unselect excluded entries
        for idx, (_, line) in enumerate(self.games):
            if line in self.excluded:
                sl.deselect(idx)

        self._update_label()

    # ---------------- LOGIC ----------------

    def _get_prefix(self, selected: int) -> str:
        if self.max_games == 0:
            return ""

        if selected >= self.max_games:
            return "🔴"
        elif selected > 500:
            return "🟡"
        return "🟢"

    def _update_label(self) -> None:
        sl = self.query_one("#game_list", SelectionList)
        count = len(sl.selected)

        label = self.query_one("#progress_label", Static)
        label.update(
            f"{self._get_prefix(count)} {self.tr('GAME_SELECTOR_6')}: {count} / {self.max_games}"
        )

    # ---------------- EVENTS ----------------

    @on(SelectionList.SelectedChanged)
    def on_selection_changed(self) -> None:
        sl = self.query_one("#game_list", SelectionList)

        if len(sl.selected) > self.max_games:
            sl.deselect(list(sl.selected)[-1])

        self._update_label()

    # ---------------- BUTTONS ----------------

    @on(Button.Pressed, "#select_all")
    def on_select_all(self) -> None:
        sl = self.query_one("#game_list", SelectionList)
        sl.deselect_all()

        for idx in range(min(self.max_games, len(self.games))):
            sl.select(idx)

        self._update_label()

    @on(Button.Pressed, "#select_none")
    def on_select_none(self) -> None:
        sl = self.query_one("#game_list", SelectionList)
        sl.deselect_all()
        self._update_label()

    @on(Button.Pressed, "#confirm")
    def on_confirm(self) -> None:
        sl = self.query_one("#game_list", SelectionList)

        selected = set(sl.selected)
        all_indices = set(range(len(self.games)))

        excluded_indices = all_indices - selected

        selected_lines = [self.games[i][1] for i in sorted(selected)]
        excluded_lines = [self.games[i][1] for i in sorted(excluded_indices)]

        # --- MAIN LIST (must always exist OR be deleted if empty) ---
        if selected_lines:
            with open(self.list_file, "w", encoding="utf-8") as f:
                f.write("\n".join(selected_lines) + "\n")
        else:
            self.list_file.unlink(missing_ok=True)

        # --- EXCLUDE FILE (optional output) ---
        if self.exclude_file:
            if excluded_lines:
                with open(self.exclude_file, "w", encoding="utf-8") as f:
                    f.write("\n".join(excluded_lines) + "\n")
            else:
                self.exclude_file.unlink(missing_ok=True)

        self.exit()

# ---------------- MAIN ----------------

def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("list_file")
    parser.add_argument("--max-games", type=int, required=True)
    parser.add_argument("--lang", default="eng")

    args, unknown = parser.parse_known_args()
    exclude_file = unknown[0] if unknown else None

    GameSelector(
        args.list_file,
        args.max_games,
        args.lang,
        exclude_file,
    ).run()


if __name__ == "__main__":
    main()