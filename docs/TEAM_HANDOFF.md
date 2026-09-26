# Native build handoff

Use Xcode 27.1 beta on the teammate's Mac running macOS Tahoe 26.6 or later. The coordinator's Mac is on 26.0.1, so it cannot launch that Xcode beta. This repository is work in progress; review items are not a claim of a running native demo.

1. Pull the latest published branch, open `DuoSync.xcodeproj`, and select the shared DuoSync scheme.
2. First run `scripts/build.sh` or build/run a normal iPhone Simulator to validate the baseline iOS path. Select a signing team only for physical-device builds.
3. For the Duo-specific path, add `DUO_SDK` to the target's **Swift Compiler – Custom Flags → Active Compilation Conditions**, preserving `$(inherited)` and `DEBUG` where present. Use Xcode 27.1 beta and an iOS 27.1 Duo Simulator. The same flag must be enabled for the configuration used to record the demo.
4. Run the matrix below. If an SDK signature differs, send the exact compile error and SDK version to the project coordinator; do not silently disable Duo support and call the requirement complete.

| Check | Required observation |
|---|---|
| Open app with wifi off | Bundled reading page renders |
| Select → pet → Explore | Exact selected quote and bundled explanation appear; no lost selection |
| Pet tap and drag | Tap toggles once; drag does not toggle; target stays reachable after rotation |
| Closed-state pet bubble | Loading, selection capture, result, and error each show the matching short update; tapping the bubble opens the workspace; no claim of live AI appears |
| Pet roster | Choose Corgi, Capybara, Cat, Bunny, Pixel Clip, Bouncy Disc, and Pocket Snake from the workspace menu; each sprite is distinct and the choice survives relaunch |
| Close/reopen | Browser scroll and explanation stay associated |
| New page during capture | Old source/result clears, no stale completion appears |
| Invalid URL / loading failure | Clear error and working Demo recovery |
| Arbitrary web page | Selection can be captured, but no fabricated bundled explanation |
| Pendulum | 1.0 m gives about 2.006 s; 2.0 m gives about 2.837 s |
| Accessibility | VoiceOver names actions; large text remains scrollable; Reduce Motion stops decorative motion |
| Duo flat/folded/rotated/outer display | Actual ArrangementView behavior; reader, workspace, and pet usable in all poses |

Record the commit, Xcode/SDK versions, device configuration, and result in a board fact. Only the independent verifier marks a slice done. Keep review status for anything without evidence. Save recordings outside the Git repo unless intentionally publishing them.

Capture evidence from the booted Simulator at the reader, open workspace, and closed-state result bubble. After each manual interaction, run `xcrun simctl io booted screenshot /tmp/duosync-reader.png` (change the filename for each state). Use Xcode's screen recording or `xcrun simctl io booted recordVideo /tmp/duosync-demo.mov` for the full journey, and stop the recording when the flow ends. These commands capture the actual Simulator; the browser design preview does not substitute for it.

If iOS collapses selection when the assistant opens, fix capture timing before the demonstration. Do not bypass the issue by silently substituting a hard-coded quote.

Selections are captured only when the user taps **Explore selection**. Existing source cards are snapshots; social-feed updates and history-only single-page-app navigation do not automatically refresh them. Re-select and tap Explore after the page changes. The bundled reading lesson remains the reliable judged demo path.
