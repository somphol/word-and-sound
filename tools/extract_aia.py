#!/usr/bin/env python3
"""Extract the authored sound lists and UI layout from an MIT App Inventor .aia.

Only the 60 phoneme word lists, tile labels and example words are extracted.
The bundled IPA tables in the .aia are deliberately ignored: they are replaced
by openly licensed pronunciation data in build_corpus.py.
"""

from __future__ import annotations

import argparse
import json
import re
import shutil
import sys
import tempfile
import xml.etree.ElementTree as ET
import zipfile
from pathlib import Path

NS = "{https://developers.google.com/blockly/xml}"
HTML = "{http://www.w3.org/1999/xhtml}"

CATEGORIES = [
    ("starting", "Starting Sound", "startingSelector"),
    ("vowel", "Vowel", "vowelSelector"),
    ("ending", "Ending Sound", "endingSelector"),
]

STARTING_BLENDS = {
    "startingFEW", "startingNIOR", "startingTHROUGH",
    "startingTR", "startingBL", "startingSTR",
}
ENDING_BLENDS = {"endingKT", "endingST", "endingLM"}


def field(block: ET.Element, name: str) -> str | None:
    node = block.find(f'{NS}field[@name="{name}"]')
    return node.text if node is not None else None


def mutation(block: ET.Element, key: str) -> str | None:
    node = block.find(f"{HTML}mutation")
    return node.get(key) if node is not None else None


def unescape(text: str) -> str:
    """Undo the backslash escaping left by the App Inventor text editor."""
    return text.replace("\\'", "'").replace("\\\\", "\\")


def clean_token(token: str) -> str | None:
    token = unescape(token).strip()
    if not token:
        return None
    if re.fullmatch(r"\d+", token):
        return None
    if token == "n't":
        return None
    # Homograph markers such as bass1 and content2.
    token = re.sub(r"^([A-Za-z][A-Za-z'\-.]*?)\d+$", r"\1", token)
    if len(token) == 1 and token not in ("a", "I"):
        return None
    return token


def clean_list(raw: str) -> tuple[list[str], int, int]:
    seen: set[str] = set()
    words: list[str] = []
    dropped = 0
    duplicates = 0
    for token in raw.split():
        cleaned = clean_token(token)
        if cleaned is None:
            dropped += 1
            continue
        key = cleaned.casefold()
        if key in seen:
            duplicates += 1
            continue
        seen.add(key)
        words.append(cleaned)
    return words, dropped, duplicates


def load_scm(path: Path) -> dict:
    source = path.read_text(encoding="utf-8")
    payload = source.split("$JSON", 1)[1].rsplit("|#", 1)[0].strip()
    return json.loads(payload)


def collect_buttons(node: dict, out: dict) -> None:
    if node.get("$Type") == "Button":
        text = node.get("Text")
        if text is not None:
            out.setdefault(node["$Name"], text)
    for child in node.get("$Components", []):
        collect_buttons(child, out)


def collect_category_buttons(node: dict, prefix: str, out: list[str]) -> None:
    name = node.get("$Name", "")
    if node.get("$Type") == "HorizontalArrangement" and name.startswith(prefix):
        buttons: dict[str, str] = {}
        collect_buttons(node, buttons)
        out.extend(b for b in buttons if not any(
            b.startswith(p) for p in ("starting", "vowel", "ending")
        ) or b.startswith(prefix.removesuffix("Selector")))
    for child in node.get("$Components", []):
        collect_category_buttons(child, prefix, out)


def event_metadata(root: ET.Element) -> dict[str, dict]:
    meta: dict[str, dict] = {}
    for block in root:
        if block.get("type") != "component_event":
            continue
        component = field(block, "COMPONENT_SELECTOR")
        if not component:
            continue
        example = None
        list_key = None
        for node in block.iter(f"{NS}block"):
            if node.get("type") != "component_set_get":
                continue
            selector = field(node, "COMPONENT_SELECTOR")
            prop = field(node, "PROP")
            if selector == "example" and prop == "Text" and example is None:
                value = node.find(f'{NS}value[@name="VALUE"]')
                if value is not None:
                    text_block = value.find(f"{NS}block")
                    if text_block is not None and text_block.get("type") == "text":
                        example = field(text_block, "TEXT")
            if selector == "WordListDisplay" and prop == "Elements" and list_key is None:
                value = node.find(f'{NS}value[@name="VALUE"]')
                if value is not None:
                    var_block = value.find(f"{NS}block")
                    if var_block is not None and var_block.get("type") == "lexical_variable_get":
                        list_key = field(var_block, "VAR")
        if example or list_key:
            meta[component] = {"example": example, "listKey": list_key}
    return meta


def global_lists(root: ET.Element) -> dict[str, str]:
    lists: dict[str, str] = {}
    for block in root:
        if block.get("type") != "global_declaration":
            continue
        name = field(block, "NAME")
        if not name:
            continue
        texts = [
            node.text or ""
            for node in block.iter(f"{NS}field")
            if node.get("name") == "TEXT"
        ]
        if texts:
            lists[name] = " ".join(texts)
    return lists


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "aia",
        nargs="?",
        default=str(Path.home() / "Downloads/WordAndSound.aia"),
    )
    parser.add_argument("--out", default="data")
    args = parser.parse_args()

    aia = Path(args.aia).expanduser()
    if not aia.exists():
        print(f"error: {aia} not found", file=sys.stderr)
        return 1

    out_dir = Path(args.out)
    out_dir.mkdir(parents=True, exist_ok=True)

    with tempfile.TemporaryDirectory() as tmp:
        tmp_path = Path(tmp)
        with zipfile.ZipFile(aia) as archive:
            archive.extractall(tmp_path)

        src = next(tmp_path.glob("src/appinventor/*/*/Screen1.bky"))
        scm_path = src.with_suffix(".scm")
        scm = load_scm(scm_path)
        root = ET.parse(src).getroot()

        button_text: dict[str, str] = {}
        collect_buttons(scm["Properties"], button_text)
        events = event_metadata(root)
        all_lists = global_lists(root)

        categories = []
        lists: dict[str, list[str]] = {}
        missing: list[str] = []
        stats = []

        for cat_id, cat_title, prefix in CATEGORIES:
            ids: list[str] = []
            collect_category_buttons(scm["Properties"], prefix, ids)
            seen_ids: set[str] = set()
            ids = [i for i in ids if not (i in seen_ids or seen_ids.add(i))]
            tiles = []
            for tile_id in ids:
                meta = events.get(tile_id, {})
                list_key = (meta.get("listKey") or "").replace("global ", "")
                if not list_key or list_key not in all_lists:
                    missing.append(tile_id)
                    continue
                words, dropped, duplicates = clean_list(all_lists[list_key])
                lists[list_key] = words
                stats.append((list_key, len(words), dropped, duplicates))
                example = (meta.get("example") or "").split(" /")[0].strip()
                group = "vowel" if cat_id == "vowel" else (
                    "blend" if tile_id in STARTING_BLENDS or tile_id in ENDING_BLENDS else "single"
                )
                tiles.append(
                    {
                        "id": tile_id,
                        "label": button_text.get(tile_id, tile_id),
                        "exampleWord": example,
                        "listKey": list_key,
                        "group": group,
                    }
                )
            categories.append({"id": cat_id, "title": cat_title, "tiles": tiles})

        layout = {
            "app": {
                "name": "Word & Sound",
                "tagline": "English pronunciation drills with IPA and speech",
                "dataLicense": "CC BY-SA 4.0",
                "codeLicense": "MIT",
            },
            "categories": categories,
            "mixed": [],
        }

        (out_dir / "layout.json").write_text(
            json.dumps(layout, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
        )
        (out_dir / "authored_lists.json").write_text(
            json.dumps(lists, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
            encoding="utf-8",
        )

        icon = next(tmp_path.glob("assets/*.png"), None)
        if icon is not None:
            shutil.copy(icon, out_dir / "AppIcon.png")

    print("Extracted authored lists")
    for key, count, dropped, duplicates in stats:
        print(f"  {key:24} {count:5} words  dropped {dropped:2}  dupes {duplicates:3}")
    print(f"  total tiles: {sum(len(c['tiles']) for c in categories)}")
    print(f"  total words: {sum(len(v) for v in lists.values())}")
    if missing:
        print(f"  missing metadata: {', '.join(missing)}")
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
