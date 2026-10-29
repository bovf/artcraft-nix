#!/usr/bin/env python3
"""Validate source/lock/package contracts without running a GUI or accessing the network."""
import hashlib
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
for manifest in sorted((fonts / "fonts").glob("*manifest.txt")):
    count = 0
    for line in manifest.read_text().splitlines():
        if not line.strip() or line.startswith("#"):
            continue
        fields = [field.strip() for field in line.split("|")]
        assert len(fields) >= 8, (manifest, line)
        _, _, font, _, licence, notice, sha256, *_ = fields
        assert licence == "OFL-1.1", font
        assert (fonts / notice).is_file(), notice
        assert hashlib.sha256((fonts / font).read_bytes()).hexdigest() == sha256, font
        count += 1
    assert count, manifest
    print(f"PASS: {manifest.name} font hashes and OFL notices ({count} faces)")
git_hashes = dict(re.findall(r'"(git\+[^"\n]+)" = "(sha256-[^"\n]+)";', (root / "packages/craft.nix").read_text()))
for name, source in sources.items():
    source = Path(source)
    workspace = tomllib.loads((source / "Cargo.toml").read_text())
    cargo_lock = tomllib.loads((source / "Cargo.lock").read_text())
    locked_names = {p["name"] for p in cargo_lock["package"]}
    git_keys = {}
    for package in cargo_lock["package"]:
        git_source = package.get("source", "")
        if not git_source.startswith("git+"):
            continue
        assert re.search(r"#[0-9a-f]{40}$", git_source), git_source
        assert git_source in git_hashes, (name, git_source)
        key = (package["name"], package["version"])
        assert key not in git_keys or git_keys[key] == git_source, (name, key)
        git_keys[key] = git_source
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
        if name == "filmcraft":
            helper = (source / "apps/filmcraft/src/dev_icon.rs").read_text()
            body = helper.split("fn desktop_file_content(", 1)[1].split("fn escape_exec_argument(", 1)[0]
            strings = re.findall(r'out\.push_str\(("(?:[^"\\]|\\.)*")\);', body)
            mime = next(line for line in "".join(json.loads(s) for s in strings).splitlines() if line.startswith("MimeType="))
            desktop = (source / "packaging/linux/ai.storyteller.filmcraft.desktop").read_text()
            assert mime in desktop.splitlines(), "FilmCraft dev/packaged MIME mismatch"
            assert "fn desktop_file_matches_the_packaged_fields()" in helper
        if name == "pdfcraft":
            attribution = tomllib.loads((source / "ATTRIBUTION.toml").read_text())
            models = [m for m in attribution["fetched"] if m.get("kind") == "model"]
            ocr_source = (source / "crates/ocr/src/lib.rs").read_text()
            model_names = set(re.findall(r'pub const (?:DETECTION|RECOGNITION)_MODEL: &str = "([^"]+)";', ocr_source))
            assert model_names == {"text-detection.onnx", "text-recognition.onnx"}
            assert {model["file"] for model in models} == model_names and len(models) == 2
            ocr_manifest = tomllib.loads((source / "crates/ocr/Cargo.toml").read_text())
            assert "onnx_format" in ocr_manifest["dependencies"]["rten"]["features"]
            for model in models:
                assert re.fullmatch(r"[A-Za-z0-9._-]+\.onnx", model["file"])
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
