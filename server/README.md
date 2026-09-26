# Real conversation connection

Requires Node 22+ and an OpenAI or Anthropic API key. The example defaults to OpenAI `gpt-5-nano` with minimal reasoning and low verbosity, per the requested low-cost prototype. Keep secrets on the Mac running this server. ChatGPT/Claude subscriptions are not API keys.

From the repository root:

```sh
cp server/.env.example server/.env
# Edit server/.env locally: provider, a model your account can access, and its API key.
node --env-file=server/.env server/server.mjs
```

Open http://127.0.0.1:8766/design/pet-preview.html?embed=1. Select text in the reading, open the pet, and send a question. Your selected passage, up to 12,000 characters of its reading, and the latest 20 messages are sent to the configured provider only when you send. In screen mode, on-device OCR contributes up to five timestamped text excerpts (2,000 UTF-16 units each); no video or image is sent. The server does not save chat or page content. OpenAI requests use `store: false`; provider retention policies still apply. Responses are delivered when complete, with a 40-second timeout. Stop cancels the request; closing the workspace keeps it running while the app remains active.

For the native iOS Simulator on the **same Mac**, the default endpoint is `http://localhost:8766/api/chat`. Run this server on the teammate’s Mac alongside Xcode/Bitrig. The local server binds only to loopback: a physical phone or remote cloud simulator cannot reach it. Those require a separately hosted, authenticated HTTPS endpoint; do not expose this development server publicly.

The online folding shell is a browser design preview. It does not compile or run SwiftUI. The native project still requires Xcode and Simulator verification.

No key configured returns a visible setup error, never a canned AI response. `/api/health` reports whether configuration is present, not whether credentials have been verified. `server/.env` is ignored by Git. Never commit keys or paste them into chat.

Cost reference (checked September 26, 2026): GPT-5 nano standard text pricing is $0.05/million input tokens and $0.40/million output tokens, including billed reasoning tokens. A 3,000-input / 500-total-output-token turn is about $0.00035 (about $0.35 per 1,000 turns), excluding retries and longer history. This is an illustration, not measured app usage. The 1,600 output-token cap includes reasoning and can yield no answer if exhausted; the UI handles that as an error. [Official model pricing](https://developers.openai.com/api/docs/models/gpt-5-nano).
