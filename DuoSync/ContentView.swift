import SwiftUI

struct ContentView: View {
    @StateObject private var browser = BrowserStore()
    @State private var workspaceOpen = false
    @State private var petPosition: CGPoint?
    @GestureState private var drag = CGSize.zero

    private let mint = Color(red: 0.48, green: 0.91, blue: 0.74)

    var body: some View {
        GeometryReader { geometry in
            let wide = geometry.size.width >= 700
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        Text("DuoSync").font(.headline)
                        Spacer()
                        Button("Demo", action: browser.loadDemo)
                    }
                    .padding()
                    HStack(spacing: 10) {
                        Image(systemName: "globe").foregroundStyle(.secondary)
                        TextField("Read here, or enter a URL", text: $browser.address)
                            .keyboardType(.URL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .submitLabel(.go)
                            .onSubmit { browser.navigate() }
                        Button(action: browser.navigate) { Image(systemName: "arrow.right.circle.fill") }
                            .accessibilityLabel("Open web address")
                    }
                    .padding(12)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                    .padding(.bottom, 12)
                    if let error = browser.errorMessage {
                        Text(error).font(.caption).foregroundStyle(.red).padding(.horizontal)
                    }
                    HStack(spacing: 0) {
                        BrowserView(store: browser)
                        if wide && workspaceOpen {
                            AssistantWorkspace(close: toggleWorkspace)
                                .frame(width: min(380, geometry.size.width * 0.45))
                        }
                    }
                }
                if !wide && workspaceOpen {
                    AssistantWorkspace(close: toggleWorkspace)
                        .frame(maxWidth: .infinity)
                        .frame(height: min(420, geometry.size.height * 0.7))
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28))
                        .padding(8)
                        .padding(.bottom, 76)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                pet(in: geometry.size)
            }
            .background(Color(.systemBackground))
        }
        .tint(Color(red: 0.10, green: 0.49, blue: 0.36))
    }

    private func toggleWorkspace() {
        withAnimation(.easeInOut(duration: 0.2)) { workspaceOpen.toggle() }
    }

    private func bounded(_ point: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(x: min(max(38, point.x), max(38, size.width - 38)),
                y: min(max(38, point.y), max(38, size.height - 38)))
    }

    private func pet(in size: CGSize) -> some View {
        let origin = bounded(petPosition ?? CGPoint(x: size.width - 46, y: size.height - 46), in: size)
        let current = bounded(CGPoint(x: origin.x + drag.width, y: origin.y + drag.height), in: size)
        return Button(action: toggleWorkspace) {
            VStack(spacing: 2) {
                HStack(spacing: 9) {
                    Capsule().frame(width: 5, height: workspaceOpen ? 5 : 10)
                    Capsule().frame(width: 5, height: workspaceOpen ? 5 : 10)
                }
                Text("⌣").font(.system(size: 19, weight: .bold))
            }
            .foregroundStyle(Color(red: 0.06, green: 0.19, blue: 0.15))
            .frame(width: 62, height: 62)
            .background(mint, in: RoundedRectangle(cornerRadius: 24))
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(.white.opacity(0.7), lineWidth: 2))
            .shadow(color: .black.opacity(0.15), radius: 12, y: 5)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(workspaceOpen ? "Close assistant workspace" : "Open assistant workspace")
        .accessibilityHint("Drag to move your companion")
        .simultaneousGesture(DragGesture(minimumDistance: 10)
            .updating($drag) { value, state, _ in state = value.translation }
            .onEnded { value in
                petPosition = bounded(CGPoint(x: origin.x + value.translation.width,
                                               y: origin.y + value.translation.height), in: size)
            })
        .position(current)
    }
}

struct AssistantWorkspace: View {
    let close: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Label("Your companion", systemImage: "sparkles").font(.headline)
                    Spacer()
                    Button(action: close) { Image(systemName: "xmark.circle.fill").font(.title2) }
                        .accessibilityLabel("Close assistant workspace")
                }
                Text("Stay curious.\nStay right here.")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                Text("This is your assistant workspace. Soon, a passage you select will become something you can explore.")
                    .foregroundStyle(.secondary)
                Label("Starter · AI not connected", systemImage: "hammer")
                    .font(.caption.weight(.semibold))
                    .padding(10)
                    .background(Color(.tertiarySystemFill), in: Capsule())
                Text("Tap the pet again to return to reading. Your page stays open.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            .padding(24)
        }
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 28))
    }
}
