# Latest handoff — earnings and shared visual direction

Pull `demo/live-session` / [draft PR #1](https://github.com/TriNguyen1110/duosync/pull/1). Finance is now the default fourth frontend, using sourced historical Alphabet FY2024 results and a computed two-year capex chart. Both native source and browser preview share warm ivory/charcoal/orange workspace styling, serif empty headline, concise replies, source card and pet controls. Finance has a restrained purple accent.

Rehearse: Finance → scroll to capex → ask why spending rose → close while answering → pet completion bubble → reopen → Feed → ask about the prior report. Current visible content and recent contexts attach automatically. Do not say these are live quotes or ten-year comparisons.

Portable checks and browser interaction checks pass; native build, Duo folding, keyboard and VoiceOver still need the teammate’s Xcode27.1 beta run. Earlier handoff notes below are historical and may describe superseded scopes.

---

# Current demo handoff — frontend clones

The latest user clarification supersedes earlier capture-first plans below: **clone familiar frontends inside DuoSync for the demo**. Default Demo apps mode provides Safari-like news, Feed and Reels, automatic visible-source attachment, recent app context, persistent chat, pet status and a real GPT-5 nano Check this response. No screen-sharing permission or actual app integration is required.

Pull `demo/live-session` / [draft PR #1](https://github.com/TriNguyen1110/duosync/pull/1), run the local server per server/README.md, and build/run with Xcode 27.1 beta on the teammate's Mac. No `SCREEN_CAPTURE_SDK` flag is needed; use `DUO_SDK` only for the native arrangement path. Please test Feed → pet → Check this → close → scroll/switch Reels → ask about current and previous content, then record the native Duo demo. First build error or screenshots are the next needed evidence.

Provider and browser interaction are verified; native build/UI remain unverified. Claim critique must show uncertainty, no fabricated verification or definitive AI-video diagnosis. The earlier implementation history is retained below for context, not the current rehearsal instructions.

---

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

## Real session update — September 26, 13:28 PDT

The live-chat slice adds a persistent conversation, selected-source attachment, follow-ups, Stop/retry and actual pet status. Run the local provider server from `server/README.md` on the same Mac as the iOS Simulator, then test read → select → pet → Send → close while waiting → reopen → follow-up. No provider key is configured on the coordinator’s Mac, so the online session currently shows the expected setup error. No live reply or native build has been verified.

Portable evidence: 25 Foundation tests, 10 mocked-provider server tests, Swift parsing with/without DUO_SDK and scaffold checks pass. Online preview evidence: a real selected passage was attached; Send reached the server and showed its missing-configuration error; closing showed the pet’s error bubble and reopening retained the question and attachment. Progressier uses separate inner/outer web frames, so its fold controls are only a layout preview and do not prove native folding/session continuity.


## Current handoff: actual apps + automatic screen context

Use the `demo/live-session` branch / draft PR #1. The primary UI is now Shared screen. Add `SCREEN_CAPTURE_SDK` for the iOS 27 capture implementation, and retain `DUO_SDK` only if testing the in-app fold arrangement too. The project already includes the capture usage description and screen-capture background mode. Run the provider server on the simulator's Mac; the example selects GPT-5 nano with minimal reasoning. The coordinator verified one real HTTP 200 response; the credential is local-only and is not distributed with Git.

First establish whether full-display ScreenCaptureKit works in the event's Duo Simulator (Apple's sample explicitly requires an iOS 27+ device). Then start sharing via system UI, arrange real Safari beside DuoSync, read/scroll, verify OCR timestamps and recent contexts, and ask without selecting anything. Confirm Stop/system-stop/clear, no stale OCR after stopping, portrait/landscape text recognition, and request continuity while closing the pet workspace. Five observed contexts must not be called five recent apps. The pet stays in DuoSync's app region.
