# Team source sync · September 26, 2026

Read the full shared Google Doc, “Iphone Duo Hack(YC),” and the linked planning snapshot “Prototype Siri mail orchestrator.” Reviewed the original “Dual Screen Use Explained” discussion's available content and the primary sources below. Historical chats supply product context; their technical claims are not treated as SDK guarantees.

## Current product direction

DuoSync is a general iOS agent workspace for what you are reading or browsing: articles, social feeds, PDFs, and earnings reports are all use cases. It is not a finance-only application. Its floating pet offers immediate access to contextual help; the reading surface remains available while a separate workspace shows progress, explanations, visuals, and results.

The teammate's example—read an earnings report while the agent compares ten years of capex across companies—defines the intended parallel workflow, not permission to invent historical figures or turn this build into a financial terminal. A future financial comparison must retrieve real filings, reconcile time ranges/units/definitions, calculate in code, and link every input to its source.

The first bounded demonstration uses a physics passage and a deterministic pendulum. That is a representative reading interaction, not the product boundary. Current context is captured on an explicit action inside our own browser. Continuous app-local context awareness and useful proactive suggestions are subsequent work; the app must not claim global visibility into other apps or silently upload browsing activity.

## Decisions carried into implementation

| Source requirement | Project response |
|---|---|
| Visual workspace rather than another chat-only app | Browser + contextual workspace; pet toggles it without losing place |
| Shared current-screen context | Exact source identity and selected text; navigation invalidates stale work |
| Continue reading while work runs | Asynchronous capture/provider boundary, independent progress; reading stays available |
| Rich voice and supported Siri actions | Keep replaceable provider and App Intent integration as later slices |
| Proactive help | Preserve roadmap; no always-on or cross-app claims in the PoC |
| New Duo APIs central | ArrangementView implementation path, actual fold checks on teammate's Xcode Mac |
| All code at event; polished PoC sufficient | Small working journey, 14:45 freeze, rehearsal/recording before 15:30 |

## Primary-source findings

- [Apple Duo overview](https://developer.apple.com/iphone-duo/) calls for Xcode 27.1 beta. [Arrangement guidance](https://developer.apple.com/videos/play/tech-talks/111463/) documents split/overlay arrangements and reserved regions. These support the chosen paired workspace, but only native testing can validate our implementation.
- [Apple App Schemas](https://developer.apple.com/videos/play/wwdc2026/240/) explains exposing app content/actions through entities, schemas, and intents. This is not a grant of unrestricted third-party GUI control. Siri is optional to the first browser demo.
- [GPT-Live 1 specifications](https://developers.openai.com/api/docs/models/gpt-live-1) identify audio/text support, not direct image/video input. [Delegation guidance](https://developers.openai.com/api/docs/guides/live-delegation) separates the voice interaction from backend tools/reasoning. Any later visual understanding needs a suitable backend. No provider integration is connected in this PoC.
- [Thinking Machines interaction-model research](https://thinkingmachines.ai/blog/interaction-models/) motivates simultaneous interaction and background work. A research demonstration does not establish that this project has API access; it is inspiration, not a build dependency.

The Apple system-orchestration lab link from the source could not be retrieved by the web reader during this sync; do not present its historical chat summary as a newly verified API contract. Private registration/email links and full planning transcripts are not copied into this public repository.

## Current team constraint

The user's teammate will run Xcode 27.1 beta on another Mac. This machine can check source syntax, Foundation model logic, and project structure, but cannot verify the iOS build, WebKit selection retention, accessibility interaction, or Duo folding. Keep those board items in review until evidence comes back.
