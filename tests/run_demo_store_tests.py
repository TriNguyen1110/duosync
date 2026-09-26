#!/usr/bin/env python3
"""Run production store logic with UI property wrappers stubbed; this is not a SwiftUI build."""
from pathlib import Path
import subprocess
import tempfile
root = Path(__file__).resolve().parents[1]
source = (root / "DuoSync/DemoApps.swift").read_text().split("struct DemoAppsView: View", 1)[0]
source = source.replace("import SwiftUI", """import Foundation
protocol ObservableObject {}
@propertyWrapper struct Published<Value> { var wrappedValue: Value }
enum Color { case orange, pink, black, purple, indigo, cyan, blue }
""", 1)
with tempfile.TemporaryDirectory(prefix="duosync-demo-tests-") as directory:
    work = Path(directory)
    (work / "Store.swift").write_text(source)
    subprocess.run(["swiftc", "-module-cache-path", str(work / "cache"), str(root / "DuoSync/Models.swift"), str(work / "Store.swift"), str(root / "tests/DemoAppStoreTests.swift"), "-o", str(work / "tests")], check=True)
    subprocess.run([str(work / "tests")], check=True)
