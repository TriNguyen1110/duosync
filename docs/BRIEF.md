# Product brief

**DuoSync:** a small companion living beside what you are reading. Tap its floating pet to open the assistant workspace, then tuck it away without losing your place.

For the YC × Bitrig demo, a student reads a physics passage in an embedded browser, selects an idea they do not understand, and turns it into a manipulable visual. The UI should feel contextual and immediate, with the reading surface and the explanation sharing one workspace rather than a sequence of chat pages.

The long-term ambition is an AI-native phone interface with voice, goals, and useful proactive suggestions. Those are product ambitions, not claims about what this starter supports. It is not affiliated with OpenAI/Codex and has no privileged system or cross-app access.

## Event constraint

The supplied brief specifies September 26, 2026: check-in 10:30, opening 11:00, hacking 11:30–15:30, demos/judging 15:30–17:00, awards/mingling 17:00–18:00 PDT. All project code is to be created at the hackathon; use the existing hacker kit as coordination scaffolding. This repository is initialized on the event date. Confirm reuse eligibility with organizers if their interpretation excludes workflow scaffolding.

Meaningful Duo API use is a requirement in the supplied brief. A two-column mock alone does not satisfy it. Xcode 27.1 beta and an actual Duo Simulator/device pass remain build prerequisites.

## Scope

Required demo: pet toggle/drag; persistent embedded browser; grounded selection capture; one interactive physics visual; verified Duo arrangement; rehearsed recording.

Optional after that: a server-side live reasoning provider and a short text prompt. Excluded for this event: auth, billing, mail, Uber, file cleanup, arbitrary system settings, always-on sensing, full PDF extraction, and full-duplex voice.

## UX

The mint pet is the entry point. Tap toggles the assistant; drag repositions it inside safe bounds. Use accessible labels and a large target. Show capture/progress/failure only when real. Reading remains present, and source context travels with the explanation. A compact layout overlays the workspace; Duo should preserve both surfaces around the hinge using the system arrangement.

## References

- [YC × Bitrig event](https://events.ycombinator.com/bitrig-hacks-september2026)
- [Apple Duo overview and Xcode prerequisite](https://developer.apple.com/iphone-duo/)
- [Apple arrangement and reserved-region guidance](https://developer.apple.com/videos/play/tech-talks/111463/)
- [Original hacker kit](https://github.com/TriNguyen1110/hacker-kit)

Personal email, registration links, unrelated local paths, and private planning chat links are intentionally omitted from the public brief.
