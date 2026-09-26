# DuoSync

A little companion for what you're looking at. Read articles, browse social feeds, study a PDF, or explore an earnings report with an agent workspace beside the content. The first implementation uses an embedded web browser and a floating animated pet.

**YC × Bitrig Hacks · September 26, 2026 · work in progress.** The first offline reading journey is implemented in source. Foundation context tests pass; native iOS/WebKit, pet interaction, and the compile-gated Duo layout still need the teammate’s Xcode 27.1 beta build and Simulator evidence. Live AI, voice, and PDF extraction are not connected.

## Start

1. Open `DuoSync.xcodeproj` in **Xcode 27.1 beta** for the event's Duo SDK.
2. Select the `DuoSync` scheme and an iPhone Simulator. For a device, choose your signing team and a unique bundle identifier.
3. Run. The starter loads a bundled reading page without network access. Tap the mint pet to open or close the workspace; drag it to another position. Use the address field to browse an HTTPS page.
4. Read `AGENTS.md`, `CONTRACT.md`, and `BOARD.tsv` before continuing development.

`tests/run_context_tests.sh` runs the Foundation context regressions with Command Line Tools. `python3 scripts/check_scaffold.py` checks repository wiring without Xcode. With Xcode selected, `scripts/build.sh` compiles for a generic iOS Simulator. These are different checks: the first cannot prove the app compiles or its interface works.

## The one demo we're building

Read a physics explanation → select a confusing passage → tap the pet → explore an interactive pendulum explanation → close the workspace without losing your reading position. On Duo, use the fold-aware arrangement to keep reading and exploration together.

Implemented source includes a persistent `WKWebView`, draggable animated pet, source-bound selection capture, an explicitly prewritten pendulum explanation, and an interactive small-angle visual. Arbitrary pages can supply a selection but do not receive a fabricated answer. The `DUO_SDK` build flag enables the documented native arrangement path; it still needs SDK/runtime verification.

## Build order

| Order | Deliverable | Owner |
|---|---|---|
| 1 | Compile and run the starter; verify pet, browser navigation, and close/reopen | frontend + verifier |
| 2 | Selected passage + source identity from the current browser document | backend |
| 3 | Deterministic, labeled pendulum visual and source card | frontend |
| 4 | Duo `ArrangementView` with shared browser/workspace state | frontend |
| 5 | Optional live reasoning through a server-side provider | backend |
| 6 | Simulator/device rehearsal, recording, and pitch | verifier + main |

Freeze features at **14:45 PDT**. Use **14:45–15:15** for verification and recording, then submission/rehearsal before the **15:30** judging window. Do not spend the deadline on voice, auth, email, ride booking, or system settings.

## Hacker kit

Adapted from [TriNguyen1110/hacker-kit](https://github.com/TriNguyen1110/hacker-kit): separate state and UI owners, an append-only board, and a verifier who alone can mark work done. The local source kit is unchanged. Removed scraper, Port, dashboard tooling, and fixed model overrides; shortened ticks to 20 minutes; added native Simulator and Duo checks. `CLAUDE.md` points to the same rules as Codex.

See [the brief](docs/BRIEF.md), [source sync](docs/SOURCE_SYNC.md), [native handoff](docs/TEAM_HANDOFF.md), [pet asset and prompt](docs/PET_ASSET.md), and [motion preview](design/pet-preview.html). MIT licensed.
