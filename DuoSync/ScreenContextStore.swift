import Foundation
import Combine

/// Text only, held in memory. Screen identity is never presented as an app identifier.
@MainActor
final class ScreenContextStore: ObservableObject {
    @Published private(set) var isCapturing = false
    @Published private(set) var isStarting = false
    @Published private(set) var statusMessage = "Screen sharing is off."
    @Published private(set) var errorMessage: String?
    @Published private(set) var snapshots: [ScreenSnapshot] = []
    @Published private var currentID: UUID?
    private var engine: AnyObject?
    private var generation = UUID()
    private var clearedAt = Date.distantPast

    var isSupported: Bool {
        #if SCREEN_CAPTURE_SDK && canImport(ScreenCaptureKit)
        if #available(iOS 27.0, *) { return true }
        #endif
        return false
    }

    var currentSnapshot: ScreenSnapshot? {
        guard isCapturing, let currentID else { return nil }
        return snapshots.first { $0.id == currentID }
    }

    func startCapture() {
        guard !isStarting, !isCapturing else { return }
        guard isSupported else {
            errorMessage = "Screen context requires an iOS 27 device and a build with SCREEN_CAPTURE_SDK enabled."
            statusMessage = "Screen capture is unavailable in this build."
            return
        }
        #if SCREEN_CAPTURE_SDK && canImport(ScreenCaptureKit)
        if #available(iOS 27.0, *) {
            generation = UUID()
            let token = generation
            errorMessage = nil
            isStarting = true
            statusMessage = "Choose your display in the system sharing picker."
            let capture = ScreenCaptureEngine(
                onStarted: { [weak self] in
                    guard let self, self.generation == token else { return }
                    self.isStarting = false
                    self.isCapturing = true
                    self.statusMessage = "Sharing screen. Waiting for readable text…"
                },
                onText: { [weak self] text, date in
                    guard let self, self.generation == token, self.isCapturing else { return }
                    self.receive(text, at: date)
                },
                onStopped: { [weak self] error in
                    guard let self, self.generation == token else { return }
                    self.isStarting = false
                    self.isCapturing = false
                    self.currentID = nil
                    self.errorMessage = error
                    self.statusMessage = error == nil ? "Screen sharing stopped." : "Screen sharing needs attention."
                    self.engine = nil
                })
            engine = capture
            capture.present()
        }
        #endif
    }

    func stopCapture() {
        generation = UUID()
        let token = generation
        isStarting = false
        isCapturing = false
        currentID = nil
        errorMessage = nil
        statusMessage = "Stopping screen sharing…"
        #if SCREEN_CAPTURE_SDK && canImport(ScreenCaptureKit)
        if #available(iOS 27.0, *), let capture = engine as? ScreenCaptureEngine {
            capture.stop { [weak self] error in
                guard let self, self.generation == token else { return }
                self.engine = nil
                self.errorMessage = error
                self.statusMessage = error == nil
                    ? "Screen sharing stopped. Recent text remains until cleared."
                    : "Text capture paused. Check the system sharing indicator."
            }
            return
        }
        #endif
        engine = nil
        statusMessage = "Screen sharing stopped. Recent text remains until cleared."
    }

    func clearHistory() {
        clearedAt = Date()
        snapshots = []
        currentID = nil
        statusMessage = isCapturing ? "History cleared. New shared frames may add context." : "Screen history cleared."
    }

    private func receive(_ text: String?, at date: Date) {
        guard date >= clearedAt else { return }
        guard let text, !text.isEmpty else {
            currentID = nil
            statusMessage = "Sharing screen. No readable text in the latest sampled frame."
            return
        }
        // Move repeat screens to the front with a fresh observation time; never grow past five.
        let previous = snapshots.first { $0.text == text }
        snapshots.removeAll { $0.text == text }
        let snapshot = ScreenSnapshot(id: previous?.id ?? UUID(), text: text, capturedAt: date)
        snapshots.insert(snapshot, at: 0)
        snapshots = Array(snapshots.prefix(5))
        currentID = snapshot.id
        statusMessage = "Shared-screen text updated locally. \(snapshots.count) recent contexts."
    }
}

#if SCREEN_CAPTURE_SDK && canImport(ScreenCaptureKit)
import ScreenCaptureKit
import Vision
import CoreMedia

@available(iOS 27.0, *)
@MainActor
private final class ScreenCaptureEngine: NSObject, SCContentSharingPickerObserver, SCStreamDelegate {
    private var stream: SCStream?
    private var output: ScreenTextOutput?
    private var active = true
    private var startTimeout: DispatchWorkItem?
    private let onStarted: () -> Void
    private let onText: (String?, Date) -> Void
    private let onStopped: (String?) -> Void

    init(onStarted: @escaping () -> Void, onText: @escaping (String?, Date) -> Void,
         onStopped: @escaping (String?) -> Void) {
        self.onStarted = onStarted
        self.onText = onText
        self.onStopped = onStopped
    }

    func present() {
        let picker = SCContentSharingPicker.shared
        var config = SCContentSharingPickerConfiguration()
        config.allowedPickerModes = [.singleDisplay]
        config.showsMicrophoneControl = false
        config.showsCameraControl = false
        picker.defaultConfiguration = config
        picker.add(self)
        picker.isActive = true
        picker.present()
    }

    func stop(completion: ((String?) -> Void)? = nil) {
        active = false
        startTimeout?.cancel()
        startTimeout = nil
        let picker = SCContentSharingPicker.shared
        picker.remove(self)
        picker.isActive = false
        let stopping = stream
        stream = nil
        output = nil
        // Retain the stream through completion; no frames can reach the store after generation changes.
        guard let stopping else { completion?(nil); return }
        stopping.stopCapture { error in
            _ = stopping
            DispatchQueue.main.async {
                completion?(error == nil ? nil : "Could not confirm screen sharing stopped. Use the system sharing control to stop it.")
            }
        }
    }

    private func finish(_ error: String?) {
        guard active else { return }
        stop()
        onStopped(error)
    }

    nonisolated func contentSharingPicker(_ picker: SCContentSharingPicker, didCancelFor stream: SCStream?) {
        DispatchQueue.main.async { [weak self] in self?.finish(nil) }
    }

    nonisolated func contentSharingPickerStartDidFailWithError(_ error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.finish("Couldn't open screen sharing. Check screen-recording permission and try again.")
        }
    }

    nonisolated func contentSharingPicker(_ picker: SCContentSharingPicker,
                                          didUpdateWith filter: SCContentFilter, for stream: SCStream?) {
        DispatchQueue.main.async { [weak self] in self?.start(filter: filter) }
    }

    private func start(filter: SCContentFilter) {
        guard active, stream == nil else { return }
        let config = SCStreamConfiguration()
        config.capturesAudio = false
        config.captureMicrophone = false
        config.minimumFrameInterval = CMTime(value: 3, timescale: 1)
        let newStream = SCStream(filter: filter, configuration: config, delegate: self)
        let textOutput = ScreenTextOutput { [weak self, weak newStream] text, date in
            DispatchQueue.main.async {
                guard let self, self.active, self.stream === newStream else { return }
                self.onText(text, date)
            }
        }
        do {
            try newStream.addStreamOutput(textOutput, type: .screen, sampleHandlerQueue: textOutput.queue)
            output = textOutput
            stream = newStream
            let timeout = DispatchWorkItem { [weak self] in self?.finish("Screen sharing timed out while starting. Try again.") }
            startTimeout = timeout
            DispatchQueue.main.asyncAfter(deadline: .now() + 15, execute: timeout)
            newStream.startCapture { [weak self, weak newStream] error in
                DispatchQueue.main.async {
                    guard let self, self.active, self.stream === newStream else { return }
                    self.startTimeout?.cancel()
                    self.startTimeout = nil
                    if error != nil { self.finish("Couldn't start screen capture. Check permission and try again.") }
                    else { self.onStarted() }
                }
            }
        } catch {
            finish("Couldn't attach screen capture output. Try sharing again.")
        }
    }

    nonisolated func stream(_ stream: SCStream, didStopWithError error: Error) {
        DispatchQueue.main.async { [weak self] in
            guard let self, self.stream === stream else { return }
            self.finish("Screen sharing ended. Start sharing again to refresh context.")
        }
    }
}

/// This output and its throttling state are accessed only on the serial sample queue.
@available(iOS 27.0, *)
private final class ScreenTextOutput: NSObject, SCStreamOutput {
    let queue = DispatchQueue(label: "duosync.screen-ocr", qos: .utility)
    private var lastSample = Date.distantPast
    private let deliver: (String?, Date) -> Void

    init(deliver: @escaping (String?, Date) -> Void) { self.deliver = deliver }

    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .screen, sampleBuffer.isValid else { return }
        let now = Date()
        guard now.timeIntervalSince(lastSample) >= 3 else { return }
        lastSample = now
        guard let attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, createIfNecessary: false) as? [[SCStreamFrameInfo: Any]],
              let raw = attachments.first?[.status] as? Int,
              SCFrameStatus(rawValue: raw) == .complete,
              let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            deliver(nil, now)
            return
        }
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false
        do {
            try VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
            let lines = (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }
            var text = String(lines.joined(separator: "\n").prefix(2_000))
            while text.utf16.count > 2_000 { text.removeLast() }
            deliver(text.trimmingCharacters(in: .whitespacesAndNewlines), now)
        } catch {
            deliver(nil, now)
        }
    }
}
#endif
