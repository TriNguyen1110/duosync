# DuoSync

A floating pet assistant for whatever you're looking at. The hackathon demo contains **frontend clones** of a Finance earnings reader, Safari-style news, a social feed, and Reels. Scroll naturally; the assistant automatically gets the visible article/post/reel and recent demo-app context. Tap the pet to open a persistent workspace beside the content, ask a question, or choose **Check this**.

**YC × Bitrig · September 26, 2026.** Native SwiftUI source and a browser interaction preview are included. Real GPT-5 nano responses work through the local server. Native Xcode compilation and Duo Simulator interaction remain unverified on this Mac.

## Run the current demo branch

```sh
git clone --branch demo/live-session https://github.com/TriNguyen1110/duosync.git
cd duosync
open DuoSync.xcodeproj
```

For an existing checkout, preserve local edits, then fetch and switch to `demo/live-session`. The active handoff is [draft PR #1](https://github.com/TriNguyen1110/duosync/pull/1).

1. On the teammate's Mac, open the project in **Xcode 27.1 beta** and select the DuoSync scheme / iPhone Duo simulator.
2. Run the [local assistant server](server/README.md) on that same Mac. Set the API key only in ignored `server/.env`; no credentials belong in Swift, the browser, or Git. The default example uses **GPT-5 nano**, minimal reasoning and short replies.
3. Run the app. **Demo apps is the default source**. No screen-recording permission, selection, login or real social account is required. Start in Finance, or choose Browser, Feed or Reels; tap the pet; ask about the visible content.
4. Add `DUO_SDK` to target → Build Settings → Active Compilation Conditions for the documented fold-aware arrangement; without it, ordinary adaptive split/overlay layout runs. The Duo SDK path still needs native testing.

The primary demo does **not** need `SCREEN_CAPTURE_SDK`. System screen sharing and the owned live browser remain experimental sources in the optional menu; they are not part of the rehearsal path.

## Earnings demo

Finance opens with a Yahoo Finance–inspired reading surface and sourced **Alphabet FY2024 annual results**. Scroll to capital expenditure, then ask “Why did spending jump?” The source follows automatically, and the assistant gives a short explanation while you keep reading. Close/reopen with the pet; switch to Feed without losing the conversation.

The two-year chart compares $32.3B (2023) and $52.5B (2024); approximately 62.5% growth is calculated from rounded reported amounts. Revenue, operating income, margin and EPS come from [Alphabet’s 2024 Form 10-K](https://www.sec.gov/Archives/edgar/data/1652044/000165204425000014/goog-20241231.htm). These are historical results, not live quotes; no ten-year or peer series is invented. The warm ivory shell, serif workspace headline, source card and composer align with the teammate’s reference while keeping DuoSync’s pets.

## Feed demo journey

1. Open Feed and read the implausible five-second battery charging claim.
2. Tap the pet → **Check this**. A real model response explains missing specs, absent sources, and what evidence would support the claim.
3. Close the workspace. The pet shows actual waiting/completion/error status while you continue browsing.
4. Switch to Reels and scroll to the stylized city. Ask “Could this be AI?” The answer must distinguish available clues from missing provenance, not pretend that text alone proves how a video was created.
5. Ask about the previous battery post. Recent demo-app context and conversation remain available.

Four demo frontends are included. The recent-context store can hold five distinct demo apps, currently at most four. It updates the visible passage/card as you scroll and remembers each demo app's latest context. Finance contains sourced historical results; social/news personas, claims and study details are fictional demonstration content. Likes/saves affect local prototype state only.

**Check this is a contextual critique, not a verified fact-check or forensic AI detector.** The model sees visible text/captions and descriptions of demo artwork; it does not search the web or inspect real video frames. It identifies unsupported claims, explains uncertainty, and suggests what evidence to check.

## Preview the interaction now

Start the server, then open:

`http://127.0.0.1:8766/design/demo-session.html`

Paste that URL into the [online Duo layout shell](https://progressier.com/iphone-duo-simulator). This preview has the same demo journeys, automatic context, pet roster and live response connection. It is a browser rendition, not a compiled iOS app. The shell uses separate inner/outer web frames, so fold continuity there does not prove native state handling.

The older [pet gallery](design/pet-preview.html) remains an asset playground. The [new session frontend](design/demo-session.html) is the demo preview.

## Xcode, Device Hub and Bitrig

Device Hub shows the app built by Xcode; it cannot run a repository URL. Install Xcode 27.1 beta and the iOS 27.1 runtime, choose/create an iPhone Duo run destination, then press ⌘R. If needed, use Xcode → Open Developer Tool → Device Hub or Manage Devices in the destination menu. A physical iPhone additionally needs pairing, signing and Developer Mode.

Bitrig can open the existing local Xcode project and display its folding simulator. It still needs the appropriate Xcode and simulator runtime. Its exact import UI has not been tested on this Mac; use Xcode/Device Hub if blocked. [Apple Device Hub](https://developer.apple.com/documentation/xcode/managing-your-simulated-and-physical-devices-in-device-hub) · [Bitrig Duo setup](https://bitrig.com/blog/bitrig-builds-iphone-duo-apps).

## Validation and deadline

- `python3 scripts/check_scaffold.py`: project/resource wiring only.
- `bash tests/run_context_tests.sh`: 35 Foundation source/transport/screen-payload cases.
- `python3 tests/run_demo_store_tests.py`: 13 production demo-store state cases with UI wrappers stubbed.
- `node --test tests/server.test.mjs`: 11 server/provider mapping and failure/cancellation cases using mocked providers.
- `scripts/build.sh`: actual Simulator build, requires Xcode.

Browser-tested: automatic feed context → real GPT-5 nano claim critique → pet close → Reels switch/scroll → new current context with the prior conversation intact. Native rendering, scrolling, fold layout and accessibility still need the teammate's build and interaction evidence. Do not equate portable parsing/tests with native success.

Feature freeze **14:45 PDT**; use the remaining window for native verification/recording before **15:30** judging. See [current team handoff](docs/TEAM_HANDOFF.md). Adapted from [hacker-kit](https://github.com/TriNguyen1110/hacker-kit): bounded UI/state owners, append-only `BOARD.tsv`, separate verifier. MIT licensed.
