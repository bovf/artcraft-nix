#!/usr/bin/env python3
"""Validate source/lock/package contracts without running a GUI or accessing the network."""
import json
from pathlib import Path
import re
import sys
import tomllib

NAMES = set("photocraft artcraft lightcraft filmcraft pdfcraft vectorcraft effectcraft designcraft wordcraft cadcraft gridcraft deckcraft soundcraft".split())


def check_lock(lock):
    inputs = lock["nodes"][lock["root"]]["inputs"]
    assert set(inputs) == NAMES | {"nixpkgs", "craft-fonts", "rust-overlay"}, "Unexpected flake input set"
    for name, node_name in inputs.items():
        node = lock["nodes"][node_name]
        pinned = node["locked"]
        assert pinned["type"] == "github", name
        assert re.fullmatch(r"[0-9a-f]{40}", pinned["rev"]), name
        assert pinned["narHash"].startswith("sha256-"), name
        if name in {"nixpkgs", "rust-overlay"}:
            expected = {"nixpkgs": ("NixOS", "nixpkgs"), "rust-overlay": ("oxalica", "rust-overlay")}[name]
            assert (pinned["owner"], pinned["repo"]) == expected, name
        else:
            assert pinned["owner"] == "storytold" and pinned["repo"] == name, name
            assert node["flake"] is False, name


root, fonts = map(Path, sys.argv[1:3])
lock = json.loads((root / "flake.lock").read_text())
check_lock(lock)
sources = dict(arg.split("=", 1) for arg in sys.argv[3:])
assert set(sources) == NAMES
assert (fonts / "fonts/manifest.txt").is_file()
assert (fonts / "ATTRIBUTION.md").is_file()
assert list((fonts / "fonts").glob("*/OFL.txt"))
for name, source in sources.items():
    source = Path(source)
    workspace = tomllib.loads((source / "Cargo.toml").read_text())
    cargo_lock = tomllib.loads((source / "Cargo.lock").read_text())
    locked_names = {p["name"] for p in cargo_lock["package"]}
    assert name in locked_names, name
    if name == "artcraft":
        assert (source / "LICENSE.md").is_file()
        assert (source / "frontend/package-lock.json").is_file()
        assert list((source / ".sqlx").glob("*.json")), "ArtCraft must ship offline SQL query metadata"
        config = json.loads((source / "crates/desktop/artcraft/tauri.conf.json").read_text())
        assert config["identifier"] == "ai.artcraft.app"
    else:
        assert name + "-cli" in locked_names, name
        assert workspace["workspace"]["package"]["license"] == "MIT OR Apache-2.0", name
        assert (source / f"apps/{name}/Cargo.toml").is_file()
        assert (source / f"packaging/linux/ai.storyteller.{name}.desktop").is_file()
        assert (source / f"assets/app-icon/hicolor/256x256/apps/ai.storyteller.{name}.png").is_file()
        assert (source / f"packaging/linux/ai.storyteller.{name}.mime.xml").is_file()
        if name == "pdfcraft":
            attribution = tomllib.loads((source / "ATTRIBUTION.toml").read_text())
            models = [m for m in attribution["fetched"] if m.get("kind") == "model"]
            assert models
            for model in models:
                assert re.fullmatch(r"[A-Za-z0-9._-]+\.rten", model["file"])
                assert model["licence"] == "CC-BY-SA-4.0"
                assert re.fullmatch(r"[0-9a-f]{64}", model["sha256"])
                assert re.fullmatch(r"[0-9a-f]{64}", model["licence_sha256"])
    print(f"PASS: {name} pinned source, dependency lock and packaging assets")
# Negative control: floating/invalid source pins must not pass the contract.
bad = json.loads(json.dumps(lock))
bad["nodes"][bad["nodes"][bad["root"]]["inputs"]["photocraft"]]["locked"]["rev"] = "main"
try:
    check_lock(bad)
except AssertionError:
    print("PASS: floating revision rejected")
else:
    raise AssertionError("Floating source revision was accepted")
