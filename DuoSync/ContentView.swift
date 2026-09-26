import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var browser = BrowserStore()
    @State private var workspaceOpen = false
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
                    DuoLayout(workspaceOpen: workspaceOpen) {
                        BrowserView(store: browser)
                    } workspace: {
                        AssistantWorkspace(browser: browser, selectedSpecies: $selectedSpecies,
                                           close: toggleWorkspace)
                    }
                }
                companion(in: geometry.size)
            }
            .background(Color(.systemBackground))
        }
        .tint(Color(red: 0.10, green: 0.49, blue: 0.36))
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
                Button("Demo", action: browser.loadDemo)
                    .font(.subheadline.weight(.semibold))
                    .padding(.vertical, 10).padding(.horizontal, 14)
                    .background(Color.accentColor.opacity(0.09), in: Capsule())
            }
            HStack(spacing: 10) {
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
            if let error = browser.errorMessage, !workspaceOpen {
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
        if browser.isCapturing { return "One tiny moment. Reading your selection…" }
        if browser.errorMessage != nil { return "A little plot twist. Tap me to take a look." }
        if browser.explanation != nil { return "Aha! Your little lesson is ready." }
        if browser.context != nil { return "Quote captured. Live explanations aren’t connected yet." }
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
                activity: browser.isCapturing ? .capturing : (browser.explanation == nil ? .idle : .ready),
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
            .accessibilityValue(browser.isCapturing ? "Reading selection" : (browser.explanation == nil ? "Ready to explore" : "Explanation ready"))
            .accessibilityAction { toggleWorkspace() }
            .position(current)
        }
    }
}

struct AssistantWorkspace: View {
    @ObservedObject var browser: BrowserStore
    @Binding var selectedSpecies: String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let close: () -> Void

    private var species: CompanionSpecies { CompanionSpecies(rawValue: selectedSpecies) ?? .corgi }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Label("\(species.title) companion", systemImage: "sparkles")
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer()
                Menu {
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
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if browser.isCapturing {
                        ProgressView("Reading your selection…")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    if let error = browser.errorMessage {
                        Label(error, systemImage: "exclamationmark.circle")
                            .font(.subheadline).foregroundStyle(.red)
                    }
                    if let explanation = browser.explanation, let context = browser.context {
                        Label(explanation.mode == "bundled-demo" ? "Bundled demo · works offline" : "Live explanation", systemImage: "checkmark.seal")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.accentColor)
                        Text(explanation.explanation).font(.body)
                        sourceCard(title: context.title, url: explanation.sourceURL, quote: explanation.quote)
                        if explanation.visual == "pendulum" { PendulumView() }
                        Button("Clear explanation", action: browser.clearExplanation)
                            .font(.footnote)
                    } else {
                        Text("Make the idea\nclick.")
                            .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        Text("Select a passage in your reading, then explore it here. Start with the bundled pendulum lesson.")
                            .foregroundStyle(.secondary)
                        if let context = browser.context {
                            sourceCard(title: context.title, url: context.url, quote: context.selection)
                        }
                        Label("Bundled lesson only · live AI not connected", systemImage: "leaf")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Button(action: browser.exploreSelection) {
                        Label(browser.isCapturing ? "Reading selection…" : "Explore selection", systemImage: "sparkles")
                            .font(.headline)
                            .frame(maxWidth: .infinity).padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(browser.isCapturing)
                    Text("Close this panel to select another passage. Your page stays open.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                .padding(20).padding(.bottom, 70)
            }
        }
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 26))
    }

    private func sourceCard(title: String, url: URL, quote: String) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Label("From your reading", systemImage: "text.quote")
                .font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            Text(title).font(.subheadline.weight(.semibold))
            if url.isFileURL {
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
