# DuoSync

A little companion for what you're looking at. Read articles, browse social feeds, study a PDF, or explore an earnings report with an agent workspace beside the content. The first implementation uses an embedded web browser and a floating animated pet.

**YC × Bitrig Hacks · September 26, 2026 · work in progress.** The first offline reading journey is implemented in source. Foundation context tests pass; native iOS/WebKit, pet interaction, and the compile-gated Duo layout still need the teammate’s Xcode 27.1 beta build and Simulator evidence. Real conversation transport is implemented for OpenAI or Anthropic via a local server; provider credentials and an actual model round-trip remain unverified. Voice and PDF extraction are not connected.

## Start

Get the project on the Mac that has Xcode:

```sh
git clone https://github.com/TriNguyen1110/duosync.git
cd duosync
open DuoSync.xcodeproj
```

If you already cloned it, run `git pull --ff-only` from that checkout before opening the project. Commit or otherwise preserve your own edits before updating; do not discard teammates' work.

1. Open `DuoSync.xcodeproj` in **Xcode 27.1 beta** for the event's Duo SDK.
2. Select the `DuoSync` scheme and an iPhone Simulator. For a device, choose your signing team and a unique bundle identifier.
3. Run. The starter loads a bundled reading page without network access. While the workspace is closed, the pet shows a short speech-bubble update based on page loading, selection capture, results, or errors. Tap the pet or bubble to open the workspace; tap the pet or close control to close it. Drag the pet to another position. Choose a pixel-art animal or retro companion from the workspace menu. Use the address field to browse an HTTPS page.
4. Read `AGENTS.md`, `CONTRACT.md`, and `BOARD.tsv` before continuing development.

`tests/run_context_tests.sh` runs the Foundation context regressions with Command Line Tools. `python3 scripts/check_scaffold.py` checks repository wiring without Xcode. With Xcode selected, `scripts/build.sh` compiles for a generic iOS Simulator. These are different checks: the first cannot prove the app compiles or its interface works.

## Real assistant session

Start the [local assistant server](server/README.md) on the same Mac as your iOS Simulator. Configure the provider, model, and API key only in its ignored local `server/.env`. No keys belong in the app or browser.

Select a passage → tap the pet → type a question → Send. The assistant workspace keeps the conversation and source attached for follow-up questions. Close it to keep reading; the pet shows actual waiting, completion, or error status, and reopening restores the session. Stop cancels the request. Navigating to a new document clears the native conversation so it cannot reuse the wrong source. A missing API configuration produces a setup error.

The browser session at `http://127.0.0.1:8766/design/pet-preview.html?embed=1` uses the same chat connection and can be loaded into an online Duo shell. This is an interaction preview; the SwiftUI app must still be built with Xcode/Bitrig for the native Duo demo.

## View in Device Hub

Device Hub displays the app that Xcode builds and installs on a simulator. You do not upload a GitHub URL or Swift source files to Device Hub.

1. Install **Xcode 27.1 beta** and its **iOS 27.1 Simulator runtime** on the teammate's Mac.
2. Open `DuoSync.xcodeproj`. Choose the **DuoSync** scheme in Xcode's toolbar.
3. Choose **iPhone Duo** as the run destination. If it is missing, open **Xcode → Open Developer Tool → Device Hub** (or **Manage Devices…** in the run-destination menu), click **+**, and create an iOS 27.1 / iPhone Duo simulator. Install the runtime first if that configuration is unavailable.
4. For our Duo-specific layout, select the DuoSync target → **Build Settings → Swift Compiler – Custom Flags → Active Compilation Conditions** and add `DUO_SDK` for the configuration you run. Keep the existing inherited/Debug conditions. Without this flag, the app uses its ordinary adaptive layout.
5. Press **⌘R** in Xcode. After a successful build, Xcode installs and launches the app; Device Hub opens its interactive screen automatically.
6. Tap **Demo**, select a sentence in the reading page, tap the pet, then ask a question and **Send**. **Open bundled lesson** remains a separate prewritten visual. Use the [native handoff checklist](docs/TEAM_HANDOFF.md) to verify reading, pet, and folded layouts.

For a physical iPhone, connect it to the Mac, trust the Mac, pair it in Device Hub, and enable Developer Mode when prompted. Choose a signing team in Xcode, select that device as the run destination, and press ⌘R. In Device Hub, choose the device and **View Screen**. The hackathon Duo demo uses the simulator.

Sources: [Apple's Device Hub setup](https://developer.apple.com/documentation/xcode/managing-your-simulated-and-physical-devices-in-device-hub) and [running/interacting with the app](https://developer.apple.com/documentation/xcode/interacting-with-your-app-in-the-ios-or-ipados-simulator).

## View in Bitrig for Mac

Bitrig supports existing Xcode projects and provides a 3D folding Duo simulator. It still needs **Xcode 27.1 beta + the iOS 27.1 Simulator runtime**; it does not remove that prerequisite.

1. Clone/pull this repo locally as above.
2. Open the existing local `DuoSync.xcodeproj` in Bitrig's project-opening flow. Use this existing project rather than starting a new generated app. Exact menu labels may differ by Bitrig version; we have not tested its import UI on this Mac.
3. Configure Bitrig to use Xcode 27.1 beta and select its iPhone Duo simulator. Enable `DUO_SDK` in the project as described above.
4. Build/run the project in Bitrig. Its simulator displays the running native app and lets you fold and rotate the device. If opening the project is unclear, use the verified Xcode/Device Hub workflow above or ask the on-site Bitrig team for the current import control.

Sources: [Bitrig's Duo setup](https://bitrig.com/blog/bitrig-builds-iphone-duo-apps) and [existing team Xcode projects](https://bitrig.com/blog/turn-figma-designs-into-native-swift).

**Current verification:** these setup steps follow vendor documentation; this project's native build and simulator behavior still need to be run on the teammate's Mac. A compiler failure must be fixed before either viewer can display the app. Send the first build error and Xcode version back to the project coordinator.

## The one demo we're building

Read a passage → select it → tap the pet → ask a question → keep reading while the assistant answers → reopen for a follow-up. On Duo, keep reading and conversation side by side. The prewritten pendulum visual remains an explicitly labeled offline fallback.

Implemented source includes a persistent `WKWebView`, draggable animated pixel-art companion roster with closed-state activity bubbles, source-bound selection capture, an explicitly prewritten pendulum explanation, and an interactive small-angle visual. Bubble copy is playful but reflects local app state; it does not claim background AI work. Arbitrary readable web pages can supply a selection for real chat through the configured local server; no fabricated answer is used when the connection is missing. The `DUO_SDK` build flag enables the documented native arrangement path; it still needs SDK/runtime verification. [Preview the companion interaction](design/pet-preview.html) in a browser; this is a design preview, not the running iOS app.

## Build order

| Order | Deliverable | Owner |
|---|---|---|
| 1 | Compile and run the starter; verify pet, browser navigation, and close/reopen | frontend + verifier |
| 2 | Selected passage + source identity from the current browser document | backend |
| 3 | Deterministic, labeled pendulum visual and source card | frontend |
| 4 | Duo `ArrangementView` with shared browser/workspace state | frontend |
| 5 | Real conversation through a server-side provider | backend + main |
| 6 | Simulator/device rehearsal, recording, and pitch | verifier + main |

Freeze features at **14:45 PDT**. Use **14:45–15:15** for verification and recording, then submission/rehearsal before the **15:30** judging window. Do not spend the deadline on voice, auth, email, ride booking, or system settings.

## Hacker kit

Adapted from [TriNguyen1110/hacker-kit](https://github.com/TriNguyen1110/hacker-kit): separate state and UI owners, an append-only board, and a verifier who alone can mark work done. The local source kit is unchanged. Removed scraper, Port, dashboard tooling, and fixed model overrides; shortened ticks to 20 minutes; added native Simulator and Duo checks. `CLAUDE.md` points to the same rules as Codex.

See [the brief](docs/BRIEF.md), [source sync](docs/SOURCE_SYNC.md), [native handoff](docs/TEAM_HANDOFF.md), [pet asset and prompt](docs/PET_ASSET.md), and [motion preview](design/pet-preview.html). MIT licensed.
