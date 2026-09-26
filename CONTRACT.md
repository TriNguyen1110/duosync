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
