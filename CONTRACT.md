# Contract v0 — frozen initialization boundary

## Implemented starter surface

- `DuoSyncApp` creates `ContentView`.
- `ContentView` owns one `BrowserStore` for its lifetime, the workspace visibility flag, and pet position. Closing the workspace must not recreate the web view.
- `BrowserStore` owns one `WKWebView`; loads the bundled reading page at initialization; accepts only HTTP/HTTPS navigation from the address bar. Invalid input produces a user-visible error. No model calls or selection capture yet.
- `BrowserView` exposes the store's existing `WKWebView` through `UIViewRepresentable`.
- `AssistantWorkspace` is a placeholder, clearly labeled as such. Never pretend it has captured the page.
- Compact screens show the workspace as an overlay; wide screens place it beside the browser. This is ordinary size adaptation, not the Duo API implementation.

## Next slice — proposed data contract, not implemented endpoints

```swift
struct PageContext: Codable {
    let documentID: UUID       // replace on navigation
    let title: String
    let url: URL
    let text: String           // bounded to 12,000 characters; disclose truncation
    let selection: String     // must occur verbatim in text
    let capturedAt: Date
}

struct Explanation: Codable {
    let documentID: UUID
    let sourceURL: URL
    let quote: String          // exact excerpt from its own PageContext
    let explanation: String
    let mode: String           // "bundled-demo" or "live"
    let visual: String?        // only "pendulum" supported in the first demo
}
```

Provider boundary: `explain(context: PageContext, prompt: String) async throws -> Explanation`.
No HTTP route exists yet. Do not invent an endpoint or assume keys are available. Keep provider implementation server-side when added; the iOS client never contains a provider key.

State for the next slice: idle → capturing → ready → reasoning → ready / failed / cancelled.
Navigation invalidates the document ID and old responses. Cancellation and timeout must settle the UI. Selection capture is in-app only. JavaScript messages from a page are untrusted; validate shape, length, main frame, active navigation, and quote/source match before use.

Pendulum calculation: `T = 2π√(L/g)`, `g = 9.81 m/s²`, small-angle approximation, length constrained to 0.2–2.0 m. Deterministic controls work without a model. Live explanations cannot execute arbitrary generated code.

## Build slice 1 — agreed implementation surface

Main freezes this API for the first parallel build. `BrowserStore` stays `@MainActor` and owns the WKWebView. Backend implements it; frontend calls only these members:

- Existing: `address: String`, `errorMessage: String?`, `loadDemo()`, `navigate()`.
- Published: `context: PageContext?`, `explanation: Explanation?`, `isCapturing: Bool` (initial false).
- Action: `exploreSelection()` captures the current main-frame document and selected text, validates it, and creates a visibly bundled explanation only for the bundled pendulum page. On other pages capture source/selection but report that live reasoning is not connected; never fabricate an explanation for arbitrary content.
- Action: `clearExplanation()` clears explanation/error, retaining reading state.
- `PageContext` and `Explanation` use the fields above; `mode` is `bundled-demo` for the first slice. Define them in `DuoSync/Models.swift`.
- `BrowserStore` invalidates context/explanation on top-level navigation, ignores stale capture completions, and settles isCapturing on success/failure. No observer-induced hidden network calls.
- No DOM message bridge needed initially: explicit user action evaluates JavaScript in the owned WKWebView and validates its result. Read the selection only on that action. No provider server in this slice.
- Frontend implements the pendulum locally, with small-angle assumptions displayed. It shows context title, URL, exact quote, and the bundled label. Source citation retains document identity and never claims to represent the PDF of another URL.
- Frontend may add DuoSync/PendulumView.swift and DuoSync/DuoLayout.swift. Main alone updates project source lists after handoff. Any new dependency or model API is out of scope for this slice.

## Live conversation slice — September 26 user correction

The user now explicitly requests a real assistant conversation alongside reading, with the pet acting as the workspace toggle. This supersedes the offline-only scope for this bounded slice. Keep the bundled lesson available, but never present it as a live chat reply.

- Main owns a local Node server serving the preview and `POST /api/chat`. Provider keys stay in server environment variables. Missing configuration returns 503, never a fabricated response.
- Request: `{ "messages": [{"role":"user"|"assistant", "content":"..."}], "context": {"title":"...", "url":"...", "text":"...", "selection":"..."} }`. Maximum 20 messages, 4000 characters per message, 12000 source text, 4000 selection. Selection must be a verbatim substring. Response: `{ "text":"..." }`; errors `{ "error":"..." }`. Server/provider timeout is bounded at 40 seconds. Source text is untrusted evidence, never instructions.
- Backend owns BrowserView.swift and Models.swift. Add `ChatMessage: Identifiable` with `id: UUID`, `role: String`, `content: String`; published `messages: [ChatMessage]`, `isResponding: Bool`, and `chatError: String?`; actions `sendMessage(_ prompt: String)`, `cancelResponse()`, and `clearConversation()`. First send captures/validates selection from the current page; follow-ups may reuse current-document context. Navigation cancels in-flight response and clears conversation; closing workspace keeps it running. Cancel/fail must settle state without pretending success.
- Native endpoint is read from UserDefaults key `assistantEndpoint`, default `http://localhost:8766/api/chat` for the iOS Simulator on the same Mac as the server. No provider key in app or repo. Main owns local-network transport configuration and project settings.
- Frontend owns ContentView.swift: persistent message list, multiline composer, source attachment, Send/Stop/retry paths, and secondary pet picker. Closed-state bubble reflects actual `isResponding`/completion/error. Preserve pet behavior and Reduce Motion. Show actionable setup error if server/provider is absent.
- Online preview's `?embed=1` opens directly into reading/chat session with genuine selected passage capture and fetch to same-origin `/api/chat`. No timed fake response. Its web/device-frame status remains visibly a design preview; native Duo verification still requires the compiled app.

## Automatic screen context — user correction, September 26

- Primary experience is actual Safari/social apps beside DuoSync through system Duo multitasking. Do not build lookalike native apps or claim to embed another app's process. The owned browser remains a fallback.
- iOS 27 ScreenCaptureKit is the documented capture path: explicit system full-display picker, `NSScreenCaptureUsageDescription`, `screen-capture` background mode, and stream lifecycle. Compile behind `SCREEN_CAPTURE_SDK`; native SDK/device proof remains required.
- Backend owns standalone `ScreenContextStore.swift`, with an always-available store wrapper and supported-engine availability guard. Published state: isSupported, isCapturing, isStarting, statusMessage, errorMessage, snapshots, currentSnapshot. Actions startCapture/stopCapture/clearHistory. `ScreenSnapshot` has id, text, capturedAt; no invented app identity.
- OCR runs on-device at most every three seconds, keeping at most five distinct screen contexts in memory. No screenshots/video saved or uploaded; no microphone. Capture only after the user starts sharing, and stop from app or system UI. No retrospective access to screens before sharing. Five contexts is not an OS-provided list of five recent apps.
- Main owns `ScreenContextPayload.make(snapshots:) -> PageContext?` and `BrowserStore.sendScreenMessage(_:context:)`. Each ask sends bounded latest OCR excerpts with timestamps, newest first, and never claims a selected passage. Context URL uses the local `duosync://screen/` source identity (not a web citation). Changing UI mode clears prior conversation. Closing assistant retains it.
- Screen mode shows actual sharing status, last capture timestamp, recent contexts, and controls to stop/clear. The pet remains inside DuoSync's own app area; systemwide overlay is not implemented. Full-display capture may include DuoSync itself; provider must distinguish app UI from source content and ask when ambiguous.
- User requested the simplest/cheapest model: default OpenAI GPT-5 nano with minimal reasoning, short answers and bounded history. Keys remain server-side; model calls occur only on Send, not on every frame.

## Frontend demo clarification — supersedes capture-first demo

User explicitly clarified that familiar app frontends should be cloned for the hackathon demo, not integrated as actual apps. Make Safari-style news, social feed, and Reels-style views the default owned frontend surfaces. No accounts, real social actions, screen recording, or permission prompts are needed for this demo. Retain capture code as an experimental path only.

The assistant automatically receives the visible demo card/article as scrolling changes focus, plus up to five recently viewed demo app contexts. Preserve conversation across app switches. A small Demo label distinguishes fictional seeded material from actual Safari/social services. The pet opens/closes the assistant next to the clone surface. 'Check this' runs real GPT-5 nano on the visible source: identify unsupported claims and explain uncertainty; do not present model opinion as verified fact-checking or reliable AI-media detection. No fabricated web searches/citations/probabilities. Current transport sees text/captions, not video pixels.


## Earnings and visual sync — September 26

Add a fourth Finance frontend, initially showing sourced Alphabet FY2024 annual results (historical, not live quotes). Use revenue/operating earnings/EPS and a two-year 2023–2024 capex comparison from the official 2024 Form 10-K. Calculate growth from rounded reported $32.3B/$52.5B, label rounding; never invent ten-year or peer data. Keep fictional feed/news labels separate from these real historical figures in attached context. Preserve the other three demo apps and conversation across switches.

Match teammate’s warm ivory, charcoal, orange-accent workspace, 8px spacing rhythm, white source/composer cards and editorial serif empty-state headline. Retain DuoSync branding and pet controls. Finance uses a restrained purple accent. Preview opens the workspace at wide sizes and keeps it closed on compact screens. Verify contrast, source changes, response feedback, close/reopen persistence and compact access before handoff. Native SCREEN remains review without Xcode evidence.
