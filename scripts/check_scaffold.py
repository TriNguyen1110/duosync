#!/usr/bin/env python3
"""Validate repository wiring, not native compilation or runtime behavior."""
from pathlib import Path
import csv
import json
import subprocess
import xml.etree.ElementTree as ET

root = Path(__file__).resolve().parents[1]
required = ["README.md", "AGENTS.md", "CLAUDE.md", "CONTRACT.md", "LICENSE", "BOARD.tsv",
            "docs/BRIEF.md", "docs/DEMO.md", "docs/DUO.md", "scripts/build.sh",
            ".claude/agents/backend.md", ".claude/agents/frontend.md", ".claude/agents/verifier.md"]
for name in required:
    assert (root / name).is_file(), f"Missing {name}"

project = root / "DuoSync.xcodeproj/project.pbxproj"
result = subprocess.run(["plutil", "-convert", "json", "-o", "-", str(project)],
                        check=True, capture_output=True, text=True)
data = json.loads(result.stdout)
objects = data["objects"]
assert objects[data["rootObject"]]["isa"] == "PBXProject"
target_ids = [key for key, value in objects.items() if value["isa"] == "PBXNativeTarget"]
assert len(target_ids) == 1
target = objects[target_ids[0]]
assert target["name"] == "DuoSync"
referenced = set()
for phase_id in target["buildPhases"]:
    phase = objects[phase_id]
    for build_id in phase["files"]:
        reference = objects[objects[build_id]["fileRef"]]
        name = reference["path"]
        location = root / "DuoSync" / ("Resources" if name.endswith(".html") else "") / name
        assert (location.is_dir() if name.endswith(".xcassets") else location.is_file()), f"Unresolved build resource: {name}"
        referenced.add(name)
assert referenced == {"DuoSyncApp.swift", "BrowserView.swift", "ContentView.swift", "Reading.html",
                      "Models.swift", "PendulumView.swift", "DuoLayout.swift", "CompanionPet.swift", "ScreenContextStore.swift", "DemoApps.swift", "Assets.xcassets"}
scheme = ET.parse(root / "DuoSync.xcodeproj/xcshareddata/xcschemes/DuoSync.xcscheme")
for reference in scheme.findall(".//BuildableReference"):
    assert reference.attrib["BlueprintIdentifier"] == target_ids[0]
    assert reference.attrib["ReferencedContainer"] == "container:DuoSync.xcodeproj"

with (root / "BOARD.tsv").open() as file:
    rows = list(csv.reader(file, delimiter="\t"))
assert rows[0] == ["ts", "kind", "id", "value", "owner", "scope", "note"]
for row in rows[1:]:
    assert len(row) == 7, f"Malformed board row: {row}"
    assert row[1] in {"item", "fact"}
    if row[1] == "item":
        assert row[3] in {"backlog", "doing", "review", "done", "blocked", "delayed"}
print("PASS: project sources/resource, scheme, required files, and board format")
print("NOT CHECKED HERE: iOS compilation, native capture/UI, Duo SDK, live provider")
