# Native apps beside DuoSync: verified API boundaries

Research checked September 26, 2026 against official Apple documentation. This is a documentation review, not a compiled or device-verified implementation. The local Mac cannot run the required Xcode version.

## Supported demo shape

Run Safari or another native app beside DuoSync using the system's two-app split view. Apple's Duo engineering talk states all apps participate in this layout; its design talk describes dragging an app to the side to make the 50/50 split. DuoSync should adapt to its assigned scene, with its pet and assistant inside that scene. This demonstrates real separate apps rather than reproducing their content in an embedded browser. The user controls the split; no automatic launch/pairing API was established in this review.

Sources: [Multiple displays and scenes on iPhone Duo](https://developer.apple.com/videos/play/tech-talks/111464/), [Design for iPhone Duo](https://developer.apple.com/videos/play/tech-talks/111466/).

## Capture requires the system picker

Apple's iOS sample supports full-display capture on iOS 27 using `SCContentSharingPicker.present()`. `presentForCurrentApplication()` is limited to the current app. The returned filter starts the stream. The sample declares the `screen-capture` background mode to continue full-display capture while backgrounded. Camera overlay is explicitly unavailable for full-display capture. The framework overview requires `NSScreenCaptureUsageDescription` and permission. Our OCR feature does not need the sample's recording-to-Photos or camera functionality.

Sources: [Capturing screen content on iOS](https://developer.apple.com/documentation/screencapturekit/capturing-screen-content-on-ios), [ScreenCaptureKit](https://developer.apple.com/documentation/screencapturekit).

An implementation may retain the five most recent observed text snapshots during an authorized stream. Label them “recent observed screens,” with capture times. OCR produces extracted pixels/text, not authoritative app identity, DOM selections, source URLs, or an operating-system app-usage history. Do not label OCR guesses as verified app names. Capture stop, permission denial, empty/protected content, and stream failure must produce explicit states. Other apps may hide sensitive content during capture; never promise all screen content is available. [Apple's sensitive-content guidance](https://developer.apple.com/documentation/swiftui/protecting-sensitive-content-when-screen-sharing).

## Recent-five-app identifiers are not established

Apple's current DocC platform metadata for `SCShareableContent`, `SCRunningApplication`, and `SCShareableContent.applications` lists macOS 12.3 and Mac Catalyst 18.2, with no iOS entry. `SCContentFilter` independently lists iOS 27. Framework-level iOS availability therefore does not establish iOS availability of app enumeration. No public API returning an ordered history of the last five foreground app identifiers was found in this bounded review. Even an available-app capture list would not itself be a recency history.

Sources: [SCShareableContent](https://developer.apple.com/documentation/screencapturekit/scshareablecontent), [SCRunningApplication](https://developer.apple.com/documentation/screencapturekit/scrunningapplication), [applications](https://developer.apple.com/documentation/screencapturekit/scshareablecontent/applications), [SCContentFilter](https://developer.apple.com/documentation/screencapturekit/sccontentfilter). Platform evidence was read from each page's corresponding `https://developer.apple.com/tutorials/data/documentation/screencapturekit/<symbol>.json` metadata.

## A floating pet above another app is not verified

Apple documents `UIWindow` as hosting the app's UI; the app's windows collection excludes system-managed windows. Window level changes order within documented app-window behavior. Those APIs do not document permission to place arbitrary interactive UI above another app. No public iOS API for the requested global AssistiveTouch-like pet was found. Treat it as unsupported by the verified implementation, rather than promising that raising `windowLevel` will work.

Sources: [UIWindow](https://developer.apple.com/documentation/uikit/uiwindow), [UIApplication.windows](https://developer.apple.com/documentation/uikit/uiapplication/windows), [status-bar window level](https://developer.apple.com/documentation/uikit/uiwindow/level/statusbar).

Scene accessories are system-controlled extra scenes; the Duo camera accessory requires the app to be full screen with an active camera session. They do not establish a general overlay above Safari. Picture-in-picture is documented as a video presentation, not a generic interactive pet surface. [Duo scenes and accessories](https://developer.apple.com/videos/play/tech-talks/111464/), [Duo design](https://developer.apple.com/videos/play/tech-talks/111466/).

## Native verification still required

On an eligible iOS 27/Duo setup, test the actual Safari/social + DuoSync split, authorized full-display capture, background/foreground return, OCR orientation and deduplication, stop/clear, denied or protected capture, and the five-snapshot bound. Verify that returning to DuoSync does not flood the context with repeated captures of its own assistant UI. Never present source-level compilation or browser previews as this evidence.
