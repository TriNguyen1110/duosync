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
