import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var browser = BrowserStore()
    @StateObject private var screens = ScreenContextStore()
    @State private var screenMode = true
    @State private var workspaceOpen = false
    @State private var draft = ""
    @State private var lastSubmitted = ""
    @State private var petPosition: CGPoint?
    @State private var bubbleSize = CGSize(width: 216, height: 110)
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("companionSpecies") private var selectedSpecies = CompanionSpecies.corgi.rawValue
    @GestureState private var drag = CGSize.zero

    private var species: CompanionSpecies { CompanionSpecies(rawValue: selectedSpecies) ?? .corgi }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(spacing: 0) {
                    header
                    if screenMode {
                        if workspaceOpen {
                            assistant
                        } else {
                            ScreenContextSurface(screens: screens, openAssistant: toggleWorkspace)
                        }
                    } else {
                        DuoLayout(workspaceOpen: workspaceOpen) {
                            BrowserView(store: browser)
                        } workspace: {
                            assistant
                        }
                    }

                }
                companion(in: geometry.size)
            }
            .background(Color(.systemBackground))
        }
        .tint(Color(red: 0.10, green: 0.49, blue: 0.36))
        .onChange(of: screenMode) { _, newValue in
            if !newValue { screens.stopCapture() }
            browser.clearConversation()
            draft = ""
            lastSubmitted = ""
        }
    }

    private var assistant: some View {
        AssistantWorkspace(browser: browser, screens: screens, screenMode: screenMode,
                           selectedSpecies: $selectedSpecies, draft: $draft,
                           lastSubmitted: $lastSubmitted, close: toggleWorkspace)
    }

    private var header: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("duosync").font(.system(.title2, design: .rounded, weight: .bold))
                    Text("A little help. A deeper understanding.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                if !screenMode { Button("Demo", action: browser.loadDemo)
                    .font(.subheadline.weight(.semibold))
                    .padding(.vertical, 10).padding(.horizontal, 14)
                    .background(Color.accentColor.opacity(0.09), in: Capsule())
                }
            }
            Picker("Context source", selection: $screenMode) {
                Text("Shared screen").tag(true)
                Text("Browser fallback").tag(false)
            }
            .pickerStyle(.segmented)
            .accessibilityHint("Changing source starts a new conversation")
            Text("Switching sources starts a new chat.")
                .font(.caption2).foregroundStyle(.secondary)
            if !screenMode { HStack(spacing: 10) {
                Image(systemName: "globe").foregroundStyle(.secondary)
                TextField("Read here, or enter a URL", text: $browser.address)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.go)
                    .onSubmit { browser.navigate() }
                    .accessibilityLabel("Web address")
                Button(action: browser.navigate) {
                    Image(systemName: "arrow.right.circle.fill").font(.title2)
                }
                .accessibilityLabel("Open web address")
            }
            .padding(12)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
            }
            if !screenMode, let error = browser.errorMessage, !workspaceOpen {
                Text(error).font(.caption).foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, 18).padding(.top, 10).padding(.bottom, 12)
    }

    private func toggleWorkspace() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.24)) { workspaceOpen.toggle() }
    }

    private func bounded(_ point: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(x: min(max(38, point.x), max(38, size.width - 38)),
                y: min(max(38, point.y), max(38, size.height - 38)))
    }

    private var companionMessage: String {
        if screenMode {
            if browser.isResponding { return "Working with your remembered screens. Keep going." }
            if browser.chatError != nil || screens.errorMessage != nil { return "A little plot twist. Tap me to take a look." }
            if browser.messages.last?.role == "assistant" { return "Your reply is ready. I’ve kept your place." }
            if screens.isStarting { return "Waiting for screen sharing to start…" }
            if screens.isCapturing && screens.currentSnapshot == nil { return "Waiting for a readable screen…" }
            if !screens.snapshots.isEmpty { return "Your recent screens are here. Ask me anything about them." }
            return screens.isSupported ? "Start sharing, then use your apps. I’ll keep recent screen context here." : "Screen sharing isn’t available in this build. Browser fallback is ready."
        }
        if browser.isCapturing { return "One tiny moment. Reading your selection…" }
        if browser.isResponding { return "Working on your question. Keep reading — I’m here." }
        if browser.chatError != nil || browser.errorMessage != nil { return "A little plot twist. Tap me to take a look." }
        if browser.messages.last?.role == "assistant" { return "Aha! Your reply is ready. Want to keep going?" }
        if browser.explanation != nil { return "Your bundled lesson is ready." }
        if browser.context != nil { return "Your passage is attached. What are you wondering?" }
        if browser.isPageLoading { return "Page incoming. Getting comfy…" }
        switch species {
        case .corgi: return "All ears. Spot a curious bit? Select it, then tap me."
        case .capybara: return "No rush. Read a little. Wonder a little."
        case .cat: return "Curiosity? My specialty. Select a bit, then tap me."
        case .bunny: return "Down a rabbit hole? Select a bit. I’ll hop along."
        case .paperclip: return "Looks like you’re having a thought. I’m here for it."
        case .disc: return "A little spin on whatever you’re reading."
        case .snake: return "Sssomething interesting? Select it, then tap me."
        }
    }

    private func companion(in size: CGSize) -> some View {
        let origin = bounded(petPosition ?? CGPoint(x: size.width - 46, y: size.height - 46), in: size)
        let current = bounded(CGPoint(x: origin.x + drag.width, y: origin.y + drag.height), in: size)
        let move = DragGesture(minimumDistance: 10)
            .updating($drag) { value, state, _ in state = value.translation }
            .onEnded { value in
                petPosition = bounded(CGPoint(x: origin.x + value.translation.width,
                                               y: origin.y + value.translation.height), in: size)
            }
        return ZStack {
            if !workspaceOpen {
                Button(action: toggleWorkspace) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(species.title.uppercased())
                            .font(.caption2.weight(.bold))
                            .tracking(1.2)
                            .foregroundStyle(Color.accentColor)
                        Text(companionMessage)
                            .font(.subheadline.weight(.medium))
                            .multilineTextAlignment(.leading)
                            .lineLimit(3)
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(width: max(0, min(190, size.width - 50)), alignment: .leading)
                    .padding(13)
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18))
                        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.accentColor.opacity(0.22)))
                        .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
                }
                .buttonStyle(.plain)
                .background(GeometryReader { proxy in
                    Color.clear.preference(key: CompanionBubbleSize.self, value: proxy.size)
                })
                .onPreferenceChange(CompanionBubbleSize.self) { bubbleSize = $0 }
                .accessibilityLabel("Companion update: \(companionMessage). Open assistant workspace")
                .position(
                    x: min(max(bubbleSize.width / 2 + 12, current.x),
                           max(bubbleSize.width / 2 + 12, size.width - bubbleSize.width / 2 - 12)),
                    y: min(max(bubbleSize.height / 2 + 12,
                               current.y < size.height * 0.4
                                ? current.y + 48 + bubbleSize.height / 2
                                : current.y - 48 - bubbleSize.height / 2),
                           max(bubbleSize.height / 2 + 12, size.height - bubbleSize.height / 2 - 12)))
                .transition(.opacity)

            }
            CompanionPet(
                activity: (browser.isCapturing || browser.isResponding) ? .capturing : ((browser.messages.last?.role == "assistant" || browser.explanation != nil) ? .ready : .idle),
                workspaceOpen: workspaceOpen,
                species: species
            )
            .contentShape(RoundedRectangle(cornerRadius: 24))
            // Exclusive recognition prevents a completed drag from also toggling the panel.
            .gesture(move.exclusively(before: TapGesture().onEnded { toggleWorkspace() }))
            .accessibilityElement(children: .ignore)
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel("\(species.title) companion. \(workspaceOpen ? "Close" : "Open") assistant workspace")
            .accessibilityHint("Drag to move your companion")
            .accessibilityValue(companionMessage)
            .accessibilityAction { toggleWorkspace() }
            .position(current)
        }
    }
}

struct AssistantWorkspace: View {
    @ObservedObject var browser: BrowserStore
    @ObservedObject var screens: ScreenContextStore
    let screenMode: Bool
    @Binding var selectedSpecies: String
    @Binding var draft: String
    @Binding var lastSubmitted: String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let close: () -> Void

    private var species: CompanionSpecies { CompanionSpecies(rawValue: selectedSpecies) ?? .corgi }
    private var screenContext: PageContext? { ScreenContextPayload.make(snapshots: screens.snapshots) }

    private func send(_ prompt: String) {
        if screenMode {
            guard let context = screenContext else { return }
            browser.sendScreenMessage(prompt, context: context)
        } else {
            browser.sendMessage(prompt)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Label("\(species.title) companion", systemImage: "sparkles")
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer()
                Menu {
                    Button("New conversation", systemImage: "square.and.pencil") {
                        browser.clearConversation()
                        draft = ""
                        lastSubmitted = ""
                    }
                    Section("Animals") {
                        ForEach(CompanionSpecies.animals) { pet in
                            Button("\(pet.symbol) \(pet.title)") {
                                UISelectionFeedbackGenerator().selectionChanged()
                                withAnimation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.8)) {
                                    selectedSpecies = pet.rawValue
                                }
                            }
                        }
                    }
                    Section("Retro") {
                        ForEach(CompanionSpecies.retro) { pet in
                            Button("\(pet.symbol) \(pet.title)") {
                                UISelectionFeedbackGenerator().selectionChanged()
                                withAnimation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.8)) {
                                    selectedSpecies = pet.rawValue
                                }
                            }
                        }
                    }
                } label: {
                    Image(systemName: "pawprint.fill")
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Choose companion pet")
                Button(action: close) {
                    Image(systemName: "xmark.circle.fill").font(.title2)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Close assistant workspace")
            }
            .padding(.horizontal, 20).padding(.top, 8)
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        if browser.messages.isEmpty {
                            Text("Keep the thought going.")
                                .font(.system(.title2, design: .rounded, weight: .bold))
                            Text(screenMode ? "Use Safari or another app alongside DuoSync. Once you start screen sharing, ask about the current and recent remembered screens — no selection needed." : "Select a passage in the reader, then ask a question. This conversation stays here when you close the workspace.")
                                .font(.subheadline).foregroundStyle(.secondary)
                        }
                        if screenMode {
                            DisclosureGroup("Screen context · \(screens.snapshots.count) of 5 remembered") {
                                ScreenContextControls(screens: screens)
                                ScreenHistory(screens: screens)
                            }
                            .font(.subheadline)
                            if screens.currentSnapshot == nil {
                                ScreenContextControls(screens: screens)
                            }
                        }
                        if let context = browser.context {
                            DisclosureGroup("\(screenMode ? "Last question’s screen context" : "Attached passage") · \(context.title)") {
                                sourceCard(title: context.title, url: context.url, quote: context.selection)
                            }
                            .font(.caption)
                        }
                        ForEach(browser.messages) { message in
                            VStack(alignment: .leading, spacing: 7) {
                                Text(message.role == "user" ? "YOU" : "DUOSYNC")
                                    .font(.caption2.weight(.bold)).foregroundStyle(.secondary)
                                Text(message.content).font(.body).textSelection(.enabled)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .background(message.role == "user" ? Color.accentColor.opacity(0.08) : Color(.systemBackground), in: RoundedRectangle(cornerRadius: 18))
                        }
                        if browser.isResponding {
                            ProgressView(browser.isCapturing ? "Reading your selected passage…" : "Waiting for your assistant…")
                                .font(.subheadline)
                            Text("You can close this workspace and keep reading.")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        if let error = browser.chatError {
                            VStack(alignment: .leading, spacing: 9) {
                                Label(error, systemImage: "exclamationmark.circle")
                                    .font(.subheadline).foregroundStyle(.red)
                                if !lastSubmitted.isEmpty {
                                    Button("Retry last question") { send(lastSubmitted) }
                                        .disabled(browser.isResponding || (screenMode && screenContext == nil))
                                }
                            }
                        }
                        if !screenMode && !browser.isResponding && browser.messages.isEmpty {
                            DisclosureGroup("Try the offline pendulum lesson") {
                                VStack(alignment: .leading, spacing: 14) {
                                    Text("Bundled demo · prewritten lesson, separate from live chat")
                                        .font(.caption).foregroundStyle(.secondary)
                                    Button("Explore selected demo passage", action: browser.exploreSelection)
                                        .disabled(browser.isCapturing)
                                    if let error = browser.errorMessage { Text(error).font(.caption).foregroundStyle(.red) }
                                    if let explanation = browser.explanation {
                                        Text(explanation.explanation).font(.subheadline)
                                        if explanation.visual == "pendulum" { PendulumView() }
                                    }
                                }
                                .padding(.top, 10)
                            }
                            .font(.subheadline)
                        }
                        Color.clear.frame(height: 1).id("conversation-bottom")
                    }
                    .padding(20)
                }
                .onChange(of: browser.messages.count) { _, _ in proxy.scrollTo("conversation-bottom", anchor: .bottom) }
                .onChange(of: browser.chatError) { _, _ in proxy.scrollTo("conversation-bottom", anchor: .bottom) }
            }
            VStack(alignment: .leading, spacing: 10) {
                TextField(screenMode ? "Ask about your recent screens…" : "Ask about your selected passage…", text: $draft, axis: .vertical)
                    .lineLimit(1...5)
                    .padding(12)
                    .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 14))
                    .accessibilityLabel("Message your assistant")
                HStack {
                    Text(screenMode ? (screenContext == nil ? "Start sharing to add screen context" : "Recent \(screens.snapshots.count) screens attach on Send") : (browser.context == nil ? "Selection attaches on first send" : "Using the attached passage"))
                        .font(.caption2).foregroundStyle(.secondary)
                    Spacer()
                    if browser.isResponding {
                        Button("Stop", systemImage: "stop.fill", action: browser.cancelResponse)
                            .buttonStyle(.bordered)
                    } else {
                        Button("Send", systemImage: "arrow.up") {
                            let prompt = draft.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !prompt.isEmpty, prompt.utf16.count <= 4000 else { return }
                            lastSubmitted = prompt
                            guard !screenMode || screenContext != nil else { return }
                            send(prompt)
                            draft = ""
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || draft.utf16.count > 4000 || browser.isCapturing || (screenMode && screenContext == nil))
                    }
                }
                if draft.utf16.count > 4000 { Text("This message is too long. Shorten it to send.").font(.caption).foregroundStyle(.red) }
            }
            .padding(.horizontal, 20).padding(.top, 12).padding(.bottom, 80)
            .background(.regularMaterial)

        }
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 26))
    }

    private func sourceCard(title: String, url: URL, quote: String) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Label(screenMode ? "Recognized screen text · may contain errors" : "From your reading", systemImage: screenMode ? "rectangle.on.rectangle" : "text.quote")
                .font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            Text(title).font(.subheadline.weight(.semibold))
            if screenMode {
                Text("From user-shared screens. No app identity or page URL was inferred.")
                    .font(.caption2).foregroundStyle(.secondary)
            } else if url.isFileURL {
                Button(action: close) {
                    Label("Return to bundled reading", systemImage: "book")
                }
                .font(.caption.weight(.semibold))
                Text(url.absoluteString).font(.caption2).foregroundStyle(.secondary)
                    .textSelection(.enabled)
            } else {
                Link(destination: url) {
                    Label(url.absoluteString, systemImage: "arrow.up.right.square")
                        .font(.caption)
                }
                .accessibilityLabel("Open source: \(title)")
            }
            Text("“\(quote)”").font(.subheadline).textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 18))
    }
}

private struct CompanionBubbleSize: PreferenceKey {
    static var defaultValue = CGSize(width: 216, height: 110)
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) { value = nextValue() }
}

private struct ScreenContextSurface: View {
    @ObservedObject var screens: ScreenContextStore
    let openAssistant: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Image(systemName: "rectangle.on.rectangle")
                    .font(.largeTitle).foregroundStyle(Color.accentColor)
                Text("Your apps.\nOne conversation.")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                Text("Start screen sharing, then use Safari, social apps, or anything else you’re exploring. Return here — or place DuoSync beside another app — to ask about what you’ve seen.")
                    .foregroundStyle(.secondary)
                ScreenContextControls(screens: screens)
                Button("Open assistant", systemImage: "bubble.left.and.bubble.right", action: openAssistant)
                    .buttonStyle(.borderedProminent)
                ScreenHistory(screens: screens)
                Text("Only recognized text from the latest five distinct screens is remembered here. Screen text is sent to your configured assistant when you send a question. The companion appears inside DuoSync.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            .frame(maxWidth: 650, alignment: .leading)
            .padding(24).padding(.bottom, 160)
        }
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
    }
}

private struct ScreenContextControls: View {
    @ObservedObject var screens: ScreenContextStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(screens.isCapturing && screens.currentSnapshot == nil ? "Waiting for readable screen content" : screens.statusMessage,
                  systemImage: screens.isCapturing && screens.currentSnapshot != nil ? "record.circle" : "rectangle.dashed")
                .font(.subheadline.weight(.semibold))
            if let error = screens.errorMessage {
                Text(error).font(.caption).foregroundStyle(.red)
            }
            if screens.isSupported {
                if screens.isStarting {
                    ProgressView("Waiting for screen sharing…")
                    Button("Cancel", action: screens.stopCapture)
                } else if screens.isCapturing {
                    ViewThatFits(in: .horizontal) {
                        HStack {
                            Button("Pause sharing", systemImage: "pause", action: screens.stopCapture)
                            Button("Stop & clear", systemImage: "stop") {
                                screens.stopCapture()
                                screens.clearHistory()
                            }
                        }
                        VStack(alignment: .leading) {
                            Button("Pause sharing", systemImage: "pause", action: screens.stopCapture)
                            Button("Stop & clear", systemImage: "stop") {
                                screens.stopCapture()
                                screens.clearHistory()
                            }
                        }
                    }
                    .buttonStyle(.bordered)
                } else {
                    Button(screens.snapshots.isEmpty ? "Start screen sharing" : "Resume screen sharing", systemImage: "rectangle.on.rectangle", action: screens.startCapture)
                        .buttonStyle(.borderedProminent)
                }
            } else {
                Text("Screen sharing requires a supported iOS 27 build. You can use Browser fallback on this device.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            if !screens.snapshots.isEmpty {
                Button("Clear recent screens", role: .destructive, action: screens.clearHistory)
                    .font(.caption)
                Text(screens.isCapturing ? "Sharing is running; new screen text can appear after clearing." : "Sharing is paused or stopped. These remembered screens remain until cleared.")
                    .font(.caption2).foregroundStyle(.secondary)
                Text("Screens already sent with a question remain in that conversation until you start a new chat.")
                    .font(.caption2).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

private struct ScreenHistory: View {
    @ObservedObject var screens: ScreenContextStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent shared screens").font(.headline)
            if screens.snapshots.isEmpty {
                Text("No readable screen text yet. Nothing is attached to a question until a real screen is received.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            ForEach(Array(screens.snapshots.enumerated()), id: \.element.id) { index, snapshot in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(index == 0 ? "Latest remembered screen" : "Earlier screen")
                            .font(.caption.weight(.semibold))
                        Spacer()
                        Text(snapshot.capturedAt, style: .time).font(.caption2).foregroundStyle(.secondary)
                    }
                    Text(snapshot.text).font(.caption).lineLimit(5).textSelection(.enabled)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 16))
            }
        }
    }
}
