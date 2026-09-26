# Screen context feasibility — iOS 27

Research checked September 26, 2026 against Apple documentation. This is a source-backed implementation plan, not a native test result. No capture APIs were added by this research slice.

## What is supported

Apple now documents ScreenCaptureKit on iOS and says it replaces ReplayKit for streaming/mirroring without a broadcast extension. Screen-recording access requires the person's permission and `NSScreenCaptureUsageDescription`. Do not base the iOS 27 design on the older assumption that only a ReplayKit extension can capture outside the app. [ScreenCaptureKit overview](https://developer.apple.com/documentation/screencapturekit)

The official iOS sample requires an iOS 27+ device. It offers full-display capture through `SCContentSharingPicker.shared.present()` and app-only capture through `presentForCurrentApplication()`. An observer receives the selected `SCContentFilter` through `contentSharingPicker(_:didUpdateWith:for:)`; the sample constructs `SCStream(filter:configuration:delegate:)`, adds a `.screen` output, and starts capture. These are documented entry points, not a verified DuoSync integration. [Apple iOS capture sample](https://developer.apple.com/documentation/screencapturekit/capturing-screen-content-on-ios)

Enable `screen-capture` in `UIBackgroundModes` to continue capturing/streaming screen content while backgrounded. Apple lists this mode for iOS, iPadOS, and visionOS. Do not describe background capture as unrestricted background execution. [Background execution modes](https://developer.apple.com/documentation/xcode/configuring-background-execution-modes)

The sample additionally uses the `audio` background mode and audio-session setup for microphone capture. A screen-only DuoSync spike should omit microphone, camera, and Photos recording features unless needed; the sample's additional permissions are not blanket prerequisites for understanding visible text. This is our narrower implementation choice. [Apple iOS capture sample](https://developer.apple.com/documentation/screencapturekit/capturing-screen-content-on-ios)

## “Current screen and five recent apps” has two separate requirements

**Pixels:** a user-approved full-display stream provides a documented path to visible screen context as the person moves through apps. The stream cannot retrospectively provide screens from before capture began. This latter point is an implementation inference: build history from observed frames, not a promised system history API.

**App identity and recency:** Apple documents `SCRunningApplication.bundleIdentifier`, `applicationName`, and `processID`, obtained through shareable content. The verifier checked Apple's DocC platform metadata: `SCRunningApplication`, `SCShareableContent`, and its `applications` property list macOS/Mac Catalyst, not iOS. Do not import that desktop enumeration path into iOS or promise a chronological last-five-apps list. [SCRunningApplication](https://developer.apple.com/documentation/screencapturekit/scrunningapplication)

`SCContentFilter.includedApplications` identifies apps included by the filter; it is not documented as an app-switch event or recency ordering. The documented `SCStreamFrameInfo` keys cover frame status, time, scale, geometry, and changed regions; no foreground-app identity key is listed there. This is a documentation gap to test, not proof that every relevant iOS 27 API lacks it. [Included applications](https://developer.apple.com/documentation/screencapturekit/sccontentfilter/includedapplications), [Frame metadata](https://developer.apple.com/documentation/screencapturekit/scstreamframeinfo)

Until native evidence establishes stable app identity, label the rolling buffer “five recent captured contexts,” not “your five most recent apps.” OCR or visual recognition could infer an app label, but that inference must be distinguished from an OS-provided identifier. Never invent application names or read prior app history through guessed APIs.

## Pet visibility outside DuoSync

Capture permission supplies media, not a general cross-app overlay. UIKit documents `UIWindowScene` as managing windows belonging to the app. The current pet lives in DuoSync's view hierarchy, so it has no demonstrated ability to remain above another app. A system-wide AssistiveTouch-style pet is an unverified product requirement, not delivered behavior. [UIWindowScene](https://developer.apple.com/documentation/uikit/uiwindowscene)

Apple's iOS sample camera preview is an in-app overlay, and full-display capture does not support that camera overlay. It is not evidence for a custom cross-app pet window. Return to DuoSync or keep it visible in supported system multitasking for the first native spike. [Apple iOS capture sample](https://developer.apple.com/documentation/screencapturekit/capturing-screen-content-on-ios)

## Fast native evidence checklist

1. On the teammate's iOS 27+ device, build Apple's sample with the available Xcode 27.1 beta. Verify SDK availability and exact declarations before integrating.
2. Present the full-display picker and verify permission allow, cancel, and denial. Record capture start/stop UI and delegate outcomes.
3. Background the capture app and visit two ordinary apps. Confirm frames continue, timestamps advance, and their visible content changes. Repeat with screen-only configuration.
4. Inspect returned filter and frame attachments for reliable app identifiers; document actual keys, availability, and behavior. Do not infer recency from an unordered collection.
5. Stop sharing using system UI; ensure capture settles and retained frames are no longer presented as current. Test interruption/lock/protected or empty frames rather than assuming universal visibility. Apple exposes explicit user-stop, user-declined, and system-stop errors. [Stream errors](https://developer.apple.com/documentation/screencapturekit/error-constants)
6. Demonstrate a bounded in-memory five-context history from this consented session, with timestamps, a clear control, and honest identity labels. Device capture, background OCR, power behavior, and pet availability require evidence before declaring this journey working.

Selection-free context inside DuoSync's owned browser can be developed independently. It must be labeled browser context until the device-wide stream is integrated and verified; it does not fulfill the cross-app requirement by itself.

## Implementation handoff

`ScreenContextStore.swift` now contains a gated `SCREEN_CAPTURE_SDK` / iOS 27 engine using the documented picker and stream callbacks. It processes screen frames with local Vision OCR on a serial queue, samples at most once per three seconds, and retains at most five distinct text snapshots (2,000 UTF-16 units each), newest first. It has no audio output, recording output, image persistence, or network call. Foreground capture remains enabled for Duo split-screen use; shared-display OCR may include DuoSync itself and must not be treated as independently verified source text. OCR orientation and background behavior remain native checks. [Vision text recognition](https://developer.apple.com/documentation/vision/recognizing-text-in-images), [Stream output](https://developer.apple.com/documentation/screencapturekit/scstreamoutput), [Picker observer](https://developer.apple.com/documentation/screencapturekit/sccontentsharingpickerobserver)
