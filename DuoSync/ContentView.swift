import SwiftUI
import UIKit

private enum DuoPresentation {
    static let ivory = Color(red: 245.0 / 255, green: 243.0 / 255, blue: 235.0 / 255)
    static let charcoal = Color(red: 46.0 / 255, green: 51.0 / 255, blue: 47.0 / 255)
    static let muted = Color(red: 102.0 / 255, green: 106.0 / 255, blue: 97.0 / 255)
    static let orange = Color(red: 183.0 / 255, green: 68.0 / 255, blue: 37.0 / 255)
    static let border = Color(red: 226.0 / 255, green: 224.0 / 255, blue: 215.0 / 255)
}

private enum ContextSource: Equatable { case demo, screen, browser }
private let quickCheckPrompt = "Check the current post/article in 2–3 short sentences: assess the claim, give the strongest reason, and one thing to verify. For AI-generated media, do not claim certainty or a probability from caption/illustration alone."

struct ContentView: View {
    @StateObject private var browser = BrowserStore()
    @StateObject private var screens = ScreenContextStore()
    @StateObject private var demoStore = DemoAppStore()
    @State private var contextSource = ContextSource.demo
    private var demoMode: Bool { contextSource == .demo }
    private var screenMode: Bool { contextSource == .screen }
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
                    if demoMode {
                        DuoLayout(workspaceOpen: workspaceOpen) {
                            DemoAppsView(store: demoStore)
                        } workspace: {
                            assistant
                        }
                    } else if screenMode {
                        if workspaceOpen {
                            assistant
                        } else {
                            ScreenContextSurface(screens: screens, openAssistant: toggleWorkspace, clearSession: clearScreenSession)
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
            .background(DuoPresentation.ivory)
        }
        .foregroundStyle(DuoPresentation.charcoal)
        .tint(DuoPresentation.orange)
        .onChange(of: contextSource) { _, newValue in
            if newValue != .screen { screens.stopCapture() }
            browser.clearConversation()
            draft = ""
            lastSubmitted = ""
        }
    }

    private var assistant: some View {
        AssistantWorkspace(browser: browser, screens: screens, demoStore: demoStore,
                           screenMode: screenMode, demoMode: demoMode,
                           selectedSpecies: $selectedSpecies, draft: $draft,
                           lastSubmitted: $lastSubmitted, close: toggleWorkspace,
                           clearSession: clearScreenSession)
    }

    private func clearScreenSession() {
        browser.clearConversation()
        browser.clearExplanation()
        screens.clearHistory()
        draft = ""
        lastSubmitted = ""
    }

    private var header: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("duosync").font(.system(.title2, design: .rounded, weight: .bold))
                    Text("A little more perspective.")
                        .font(.caption).foregroundStyle(DuoPresentation.muted)
                }
                Spacer(minLength: 8)
                if demoMode {
                    Text("Demo").font(.caption.weight(.medium)).foregroundStyle(DuoPresentation.muted)
                }
                Menu {
                    Button("Demo apps") { contextSource = .demo }
                    Section("Optional sources · starts a new chat") {
                        Button("Screen sharing · experimental") { contextSource = .screen }
                        Button("Browser · experimental") { contextSource = .browser }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle").font(.title3).frame(width: 44, height: 44)
                }
                .accessibilityLabel("Choose context source")
            }
            if !screenMode && !demoMode { HStack(spacing: 8) {
                Image(systemName: "globe").foregroundStyle(DuoPresentation.muted)
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
            .background(DuoPresentation.ivory, in: RoundedRectangle(cornerRadius: 16))
            }
            if !screenMode && !demoMode, let error = browser.errorMessage, !workspaceOpen {
                Text(error).font(.caption).foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, 24).padding(.vertical, 16)
        .background(DuoPresentation.ivory)
        .overlay(alignment: .bottom) { Rectangle().fill(DuoPresentation.border).frame(height: 1) }
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
        if demoMode {
            if browser.isResponding { return "Checking the context. Keep exploring — I’m on it." }
            if browser.chatError != nil { return "A little plot twist. Tap me to take a look." }
            if browser.messages.last?.role == "assistant" { return "Your reply is ready. Want to dig a little deeper?" }
            return "Something curious? I’ve kept your recent apps in mind."
        }
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
                        .background(DuoPresentation.ivory, in: RoundedRectangle(cornerRadius: 18))
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
    @ObservedObject var demoStore: DemoAppStore
    let screenMode: Bool
    let demoMode: Bool
    @Binding var selectedSpecies: String
    @Binding var draft: String
    @Binding var lastSubmitted: String
    @FocusState private var composerFocused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let close: () -> Void
    let clearSession: () -> Void

    private var species: CompanionSpecies { CompanionSpecies(rawValue: selectedSpecies) ?? .corgi }
    private var screenContext: PageContext? {
        demoMode ? demoStore.context : ScreenContextPayload.make(snapshots: screens.snapshots)
    }
    private var automaticContext: Bool { demoMode || screenMode }

    private func send(_ prompt: String) {
        if automaticContext {
            guard let context = screenContext else { return }
            browser.sendScreenMessage(prompt, context: context)
        } else {
            browser.sendMessage(prompt)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("YOUR WORKSPACE")
                    .font(.caption.weight(.semibold)).tracking(2)
                    .foregroundStyle(DuoPresentation.muted)
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
            .padding(.horizontal, 24).padding(.vertical, 8)
            Rectangle().fill(DuoPresentation.border).frame(height: 1)
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        if demoMode {
                            DisclosureGroup {
                                ForEach(demoStore.recentContexts, id: \.documentID) { context in
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(context.title).font(.caption.weight(.semibold))
                                        Text(context.selection).font(.caption).lineLimit(4)
                                            .foregroundStyle(DuoPresentation.muted)
                                    }
                                    .padding(.vertical, 8)
                                }
                            } label: {
                                HStack(alignment: .center, spacing: 16) {
                                    Image(systemName: "doc.text")
                                        .font(.title2).foregroundStyle(DuoPresentation.muted)
                                        .frame(width: 40, height: 56)
                                        .background(DuoPresentation.ivory, in: RoundedRectangle(cornerRadius: 8))
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("PAGE CONTEXT").font(.caption2.weight(.semibold)).tracking(1.5)
                                            .foregroundStyle(DuoPresentation.muted)
                                        Text(demoStore.recentContexts.first?.title ?? "Your current app")
                                            .font(.subheadline.weight(.medium)).lineLimit(2)
                                            .foregroundStyle(DuoPresentation.charcoal)
                                        Text("Current app + \(max(0, demoStore.recentContexts.count - 1)) recent")
                                            .font(.caption).foregroundStyle(DuoPresentation.muted)
                                    }
                                }
                                .frame(minHeight: 64)
                            }
                            .font(.caption)
                            .padding(16)
                            .background(Color.white, in: RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(DuoPresentation.border, lineWidth: 1))
                        }
                        if screenMode {
                            DisclosureGroup("Screen context · \(screens.snapshots.count) of 5 remembered") {
                                ScreenContextControls(screens: screens, clearSession: clearSession)
                                ScreenHistory(screens: screens)
                            }
                            .font(.subheadline)
                            if screens.currentSnapshot == nil {
                                ScreenContextControls(screens: screens, clearSession: clearSession)
                            }
                        }
                        if let context = browser.context {
                            DisclosureGroup("\(automaticContext ? "Used for the last question" : "Attached passage") · \(context.title)") {
                                sourceCard(title: context.title, url: context.url, quote: context.selection)
                            }
                            .font(.caption)
                        }
                        if browser.messages.isEmpty {
                            VStack(alignment: .leading, spacing: 24) {
                                Image(systemName: "sparkle")
                                    .font(.system(size: 32, weight: .light))
                                    .foregroundStyle(DuoPresentation.orange)
                                Text("Stay in your flow.\nI’ll take the next step.")
                                    .font(.system(.largeTitle, design: .serif, weight: .regular))
                                    .tracking(-0.8)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text(demoMode ? "Browse freely. Your page and recent apps follow you here, so you can keep the thought going." : screenMode ? "Start sharing, then ask about what you’ve seen. Your recent screens stay close." : "Browse a page and select a passage. Your conversation stays here when you return.")
                                    .font(.body).foregroundStyle(DuoPresentation.muted)
                            }
                            .padding(.vertical, 24)
                        }
                        ForEach(browser.messages) { message in
                            VStack(alignment: .leading, spacing: 7) {
                                Text(message.role == "user" ? "YOU" : "DUOSYNC")
                                    .font(.caption2.weight(.bold)).foregroundStyle(DuoPresentation.muted)
                                Text(message.content == quickCheckPrompt ? "Check this" : message.content).font(.body).textSelection(.enabled)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .background(message.role == "user" ? DuoPresentation.orange.opacity(0.06) : Color.white, in: RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(DuoPresentation.border, lineWidth: 1))
                        }
                        if browser.isResponding {
                            ProgressView(browser.isCapturing ? "Reading your selected passage…" : "Waiting for your assistant…")
                                .font(.subheadline)
                            Text("You can close this workspace and keep reading.")
                                .font(.caption).foregroundStyle(DuoPresentation.muted)
                        }
                        if let error = browser.chatError {
                            VStack(alignment: .leading, spacing: 9) {
                                Label(error, systemImage: "exclamationmark.circle")
                                    .font(.subheadline).foregroundStyle(.red)
                                if !lastSubmitted.isEmpty {
                                    Button("Retry last question") { send(lastSubmitted) }
                                        .buttonStyle(.bordered).controlSize(.large).frame(minHeight: 44)
                                        .disabled(browser.isResponding || (automaticContext && screenContext == nil))
                                }
                            }
                        }
                        if !automaticContext && !browser.isResponding && browser.messages.isEmpty {
                            DisclosureGroup("Try the offline pendulum lesson") {
                                VStack(alignment: .leading, spacing: 14) {
                                    Text("Bundled demo · prewritten lesson, separate from live chat")
                                        .font(.caption).foregroundStyle(DuoPresentation.muted)
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
                    .padding(24)
                }
                .onChange(of: browser.messages.count) { _, _ in proxy.scrollTo("conversation-bottom", anchor: .bottom) }
                .onChange(of: browser.chatError) { _, _ in proxy.scrollTo("conversation-bottom", anchor: .bottom) }
            }
            VStack(alignment: .leading, spacing: 16) {
                if demoMode {
                    Button("Check this", systemImage: "checkmark.shield") {
                        guard screenContext != nil else { return }
                        lastSubmitted = quickCheckPrompt
                        send(quickCheckPrompt)
                    }
                    .font(.subheadline.weight(.semibold))
                    .buttonStyle(.bordered).controlSize(.large)
                    .frame(minHeight: 44)
                    .disabled(browser.isResponding || screenContext == nil)
                }
                TextField(demoMode ? "Ask about this, or something you just saw…" : screenMode ? "Ask about your recent screens…" : "Ask about your selected passage…", text: $draft, axis: .vertical)
                    .lineLimit(1...5)
                    .focused($composerFocused)
                    .frame(minHeight: 44)
                    .padding(8)
                    .accessibilityLabel("Message your assistant")
                HStack {
                    Text(demoMode ? "Current app + recent context" : screenMode ? (screenContext == nil ? "Start sharing to add screen context" : "Recent \(screens.snapshots.count) screens attach on Send") : (browser.context == nil ? "Selection attaches on first send" : "Using the attached passage"))
                        .font(.caption2).foregroundStyle(DuoPresentation.muted)
                    Spacer()
                    if browser.isResponding {
                        Button("Stop", systemImage: "stop.fill", action: browser.cancelResponse)
                            .buttonStyle(.bordered).controlSize(.large).frame(minHeight: 44)
                    } else {
                        Button("Send", systemImage: "arrow.up") {
                            let prompt = draft.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !prompt.isEmpty, prompt.utf16.count <= 4000 else { return }
                            lastSubmitted = prompt
                            guard !automaticContext || screenContext != nil else { return }
                            send(prompt)
                            draft = ""
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .frame(minHeight: 44)
                        .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || draft.utf16.count > 4000 || browser.isCapturing || (automaticContext && screenContext == nil))
                    }
                }
                if draft.utf16.count > 4000 { Text("This message is too long. Shorten it to send.").font(.caption).foregroundStyle(.red) }
            }
            .padding(16)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 24))
            .overlay(RoundedRectangle(cornerRadius: 24)
                .stroke(composerFocused ? DuoPresentation.orange : DuoPresentation.border, lineWidth: composerFocused ? 2 : 1))
            .padding(16).padding(.bottom, 72)
            .background(DuoPresentation.ivory)

        }
        .background(DuoPresentation.ivory, in: RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(DuoPresentation.border, lineWidth: 1))
    }

    private func sourceCard(title: String, url: URL, quote: String) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Label(demoMode ? "From your recent apps" : screenMode ? "Recognized screen text · may contain errors" : "From your reading", systemImage: automaticContext ? "rectangle.on.rectangle" : "text.quote")
                .font(.caption.weight(.semibold)).foregroundStyle(DuoPresentation.muted)
            Text(title).font(.subheadline.weight(.semibold))
            if demoMode {
                Text("Demo content").font(.caption2).foregroundStyle(DuoPresentation.muted)
            } else if screenMode {
                Text("From user-shared screens. No app identity or page URL was inferred.")
                    .font(.caption2).foregroundStyle(DuoPresentation.muted)
            } else if url.isFileURL {
                Button(action: close) {
                    Label("Return to bundled reading", systemImage: "book")
                }
                .font(.caption.weight(.semibold))
                Text(url.absoluteString).font(.caption2).foregroundStyle(DuoPresentation.muted)
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
        .background(Color.white, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(DuoPresentation.border, lineWidth: 1))
    }
}

private struct CompanionBubbleSize: PreferenceKey {
    static var defaultValue = CGSize(width: 216, height: 110)
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) { value = nextValue() }
}

private struct ScreenContextSurface: View {
    @ObservedObject var screens: ScreenContextStore
    let openAssistant: () -> Void
    let clearSession: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Image(systemName: "rectangle.on.rectangle")
                    .font(.largeTitle).foregroundStyle(Color.accentColor)
                Text("Your apps.\nOne conversation.")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                Text("Start screen sharing, then use Safari, social apps, or anything else you’re exploring. Return here — or place DuoSync beside another app — to ask about what you’ve seen.")
                    .foregroundStyle(DuoPresentation.muted)
                ScreenContextControls(screens: screens, clearSession: clearSession)
                Button("Open assistant", systemImage: "bubble.left.and.bubble.right", action: openAssistant)
                    .buttonStyle(.borderedProminent)
                ScreenHistory(screens: screens)
                Text("Only recognized text from the latest five distinct screens is remembered here. Screen text is sent to your configured assistant when you send a question. The companion appears inside DuoSync.")
                    .font(.footnote).foregroundStyle(DuoPresentation.muted)
            }
            .frame(maxWidth: 650, alignment: .leading)
            .padding(24).padding(.bottom, 160)
        }
        .frame(maxWidth: .infinity)
        .background(DuoPresentation.ivory)
    }
}

private struct ScreenContextControls: View {
    @ObservedObject var screens: ScreenContextStore
    let clearSession: () -> Void

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
                                clearSession()
                            }
                        }
                        VStack(alignment: .leading) {
                            Button("Pause sharing", systemImage: "pause", action: screens.stopCapture)
                            Button("Stop & clear", systemImage: "stop") {
                                screens.stopCapture()
                                clearSession()
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
                    .font(.caption).foregroundStyle(DuoPresentation.muted)
            }
            if !screens.snapshots.isEmpty {
                Button("Clear screens & conversation", role: .destructive, action: clearSession)
                    .font(.caption)
                Text(screens.isCapturing ? "Sharing is running; new screen text can appear after clearing." : "Sharing is paused or stopped. These remembered screens remain until cleared.")
                    .font(.caption2).foregroundStyle(DuoPresentation.muted)
                Text("Clear removes recent screen text, this conversation, and your draft from DuoSync. It cannot recall information already sent to the assistant server.")
                    .font(.caption2).foregroundStyle(DuoPresentation.muted)
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
                    .font(.subheadline).foregroundStyle(DuoPresentation.muted)
            }
            ForEach(Array(screens.snapshots.enumerated()), id: \.element.id) { index, snapshot in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(index == 0 ? "Latest remembered screen" : "Earlier screen")
                            .font(.caption.weight(.semibold))
                        Spacer()
                        Text(snapshot.capturedAt, style: .time).font(.caption2).foregroundStyle(DuoPresentation.muted)
                    }
                    Text(snapshot.text).font(.caption).lineLimit(5).textSelection(.enabled)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 16))
            }
        }
    }
}
