# Native build handoff

Use Xcode 27.1 beta on the teammate's Mac. This repository is work in progress; review items are not a claim of a running native demo.

1. Pull the latest published branch, open `DuoSync.xcodeproj`, and select the shared DuoSync scheme.
2. First run `scripts/build.sh` or build/run a normal iPhone Simulator to validate the baseline iOS path. Select a signing team only for physical-device builds.
3. For the Duo-specific path, add `DUO_SDK` to the target's **Swift Compiler – Custom Flags → Active Compilation Conditions**, preserving `$(inherited)` and `DEBUG` where present. Use Xcode 27.1 beta and an iOS 27.1 Duo Simulator. The same flag must be enabled for the configuration used to record the demo.
4. Run the matrix below. If an SDK signature differs, send the exact compile error and SDK version to the project coordinator; do not silently disable Duo support and call the requirement complete.

| Check | Required observation |
|---|---|
| Open app with wifi off | Bundled reading page renders |
| Select → pet → Explore | Exact selected quote and bundled explanation appear; no lost selection |
| Pet tap and drag | Tap toggles once; drag does not toggle; target stays reachable after rotation |
| Close/reopen | Browser scroll and explanation stay associated |
| New page during capture | Old source/result clears, no stale completion appears |
| Invalid URL / loading failure | Clear error and working Demo recovery |
| Arbitrary web page | Selection can be captured, but no fabricated bundled explanation |
| Pendulum | 1.0 m gives about 2.006 s; 2.0 m gives about 2.837 s |
| Accessibility | VoiceOver names actions; large text remains scrollable; Reduce Motion stops decorative motion |
| Duo flat/folded/rotated/outer display | Actual ArrangementView behavior; reader, workspace, and pet usable in all poses |

Record the commit, Xcode/SDK versions, device configuration, and result in a board fact. Only the independent verifier marks a slice done. Keep review status for anything without evidence. Save recordings outside the Git repo unless intentionally publishing them.

If iOS collapses selection when the assistant opens, fix capture timing before the demonstration. Do not bypass the issue by silently substituting a hard-coded quote.
