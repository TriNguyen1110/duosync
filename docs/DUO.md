# Duo integration — next implementation slice

Verified documentation source on September 26, 2026: [Apple: Strike a pose with adaptive layouts on iPhone Duo](https://developer.apple.com/videos/play/tech-talks/111463/). Apple's [Duo page](https://developer.apple.com/iphone-duo/) calls for Xcode 27.1 beta.

The documented `ArrangementView` takes primary and secondary views. Use the browser as primary and the assistant as secondary, with `.arrangementViewStyle(.split.axes(.horizontal))` where appropriate. It supports fold-aware layout; a hand-coded width breakpoint does not. Keep all shared context outside the arrangement so resizing or folding does not reset reading.

Confirm API signatures and availability against the installed 27.1 SDK before writing the integration. Use `GeometryProxy.reservedRegions(kind: .division)` if the pet needs custom hinge avoidance. Do not infer a fold angle from ordinary window width. The current starter uses only ordinary responsive layout and is not a Duo API demo yet.

Verification gate: run flat, partially folded, compact outer display, and rotated; show source and explanation remaining associated; pet remains reachable; closing and reopening keeps the page and context. Record actual Simulator/device evidence and mark the board only after that run. Avoid claiming API integration merely because a source symbol exists.
