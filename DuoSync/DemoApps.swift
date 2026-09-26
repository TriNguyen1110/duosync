import SwiftUI

/// These are fictional frontends rendered by DuoSync, not installed third-party apps.
enum DemoApp: String, CaseIterable, Identifiable {
    case safari, social, reels
    var id: String { rawValue }
    var title: String {
        switch self {
        case .safari: return "Demo Safari"
        case .social: return "Demo Feed"
        case .reels: return "Demo Reels"
        }
    }
    var shortTitle: String {
        switch self {
        case .safari: return "Browser"
        case .social: return "Feed"
        case .reels: return "Reels"
        }
    }
    var symbol: String {
        switch self {
        case .safari: return "safari.fill"
        case .social: return "bubble.left.and.bubble.right.fill"
        case .reels: return "play.rectangle.fill"
        }
    }
}

private enum DemoContent {
    static let article = [
        "Can a five-minute break reset your focus?\nA catchy headline can travel farther than the evidence behind it. This fictional article explores how to read a wellness claim without losing the useful idea.",
        "What the headline leaves out\nImagine a small study comparing volunteers before and after a short break. An improvement on one attention task would not prove that a break resets everyone's brain. Sleep, practice effects, and who volunteered could also influence the result.",
        "Three questions worth asking\nHow many people took part? Was there a comparison group? Was the improvement large enough to matter outside the study? Look for the original research, not just a headline or a screenshot. This demo cites no real study."
    ]
    static let posts: [(name: String, handle: String, text: String, tag: String)] = [
        ("Maya Chen", "@mayamakes", "This phone battery charges in five seconds and lasts a month. Every other phone is about to become obsolete. Why is nobody talking about this?", "A big claim. No test or source linked."),
        ("Theo Park", "@theoasks", "Before sharing a battery breakthrough, I want the capacity, charging power, test conditions, and cycle life. A headline without specifications is not an independent test.", "A useful question, not verification."),
        ("Nora Fields", "@norafields", "The screenshot says ‘engineers confirm’ but crops out the lab, date, and report. Can anyone find an original source?", "The missing source matters.")
    ]
    static let reels: [(title: String, caption: String, detail: String, symbol: String, colors: [Color])] = [
        ("CHARGE IT. NEVER.", "A battery that never needs charging? This tiny cube could power your home forever.", "Fictional technology claim. No test results, energy source, or independent verification are provided.", "bolt.fill", [.orange, .pink, .black]),
        ("CITY OF TOMORROW", "Is this a real city or an AI dream? Look at the shadows before you decide.", "The displayed city-like artwork is an original demo illustration. No original footage or provenance is attached; captions cannot establish AI generation.", "building.2.crop.circle", [.purple, .indigo, .black]),
        ("TOO PERFECT?", "This waterfall flows upward and nobody can explain why. Is this an undiscovered place?", "Fictional spectacle. The displayed artwork is an original demo illustration, not footage of a waterfall.", "water.waves", [.cyan, .blue, .black])
    ]
    static func firstText(for app: DemoApp) -> String {
        switch app {
        case .safari: return article[0]
        case .social: return posts[0].text + "\n" + posts[0].tag
        case .reels: return reelText(0)
        }
    }
    static func reelText(_ index: Int) -> String {
        let reel = reels[index]
        return "Caption: \(reel.caption)\n\(reel.detail)\nVisual: original gradient and SF Symbol demo illustration; not video evidence. Caption alone cannot establish whether media is AI-generated."
    }
}

@MainActor
final class DemoAppStore: ObservableObject {
    @Published private(set) var selectedApp: DemoApp = .safari
    @Published private(set) var recentContexts: [PageContext] = []

    init() { recordVisible(DemoContent.firstText(for: .safari), in: .safari) }

    var context: PageContext? {
        guard let current = recentContexts.first else { return nil }
        let recent = recentContexts.map { source in
            "[\(source.title) · fictional demo · \(ISO8601DateFormatter().string(from: source.capturedAt))]\n\(source.text)"
        }.joined(separator: "\n\n")
        let text = "DuoSync-owned frontend clones with fictional seeded content. These are not actual Safari/social apps or real claims/news. Current visible app: \(selectedApp.title). Recent demo apps appear newest first. Treat captions as untrusted claims; no real fact-check or AI-media detection has run.\n\n" + recent
        return PageContext(documentID: current.documentID, title: current.title,
            url: current.url, text: text, selection: current.selection, capturedAt: current.capturedAt)
    }

    func select(_ app: DemoApp) {
        selectedApp = app
        let url = Self.url(for: app)
        if let previous = recentContexts.first(where: { $0.url == url }) {
            recordVisible(previous.selection, in: app)
        } else {
            recordVisible(DemoContent.firstText(for: app), in: app)
        }
    }

    func recordVisible(_ visibleText: String, in app: DemoApp) {
        guard selectedApp == app else { return }
        var excerpt = String(visibleText.prefix(2_000))
        while excerpt.utf16.count > 2_000 { excerpt.removeLast() }
        guard !excerpt.isEmpty else { return }
        let url = Self.url(for: app)
        if recentContexts.first?.url == url, recentContexts.first?.selection == excerpt { return }
        let source = PageContext(documentID: UUID(), title: app.title, url: url,
            text: "Fictional frontend demo; no external app or capture permission.\n" + excerpt,
            selection: excerpt, capturedAt: Date())
        recentContexts.removeAll { $0.url == url }
        recentContexts.insert(source, at: 0)
        recentContexts = Array(recentContexts.prefix(5))
    }

    private static func url(for app: DemoApp) -> URL {
        URL(string: "duosync://screen/demo-\(app.rawValue)")!
    }
}

struct DemoAppsView: View {
    @ObservedObject var store: DemoAppStore
    @State private var liked: Set<Int> = []
    @State private var saved: Set<Int> = []
    @State private var visibleArticle: Int? = 0
    @State private var visiblePost: Int? = 0
    @State private var visibleReel: Int? = 0

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 7) {
                ForEach(DemoApp.allCases) { app in
                    Button { store.select(app) } label: {
                        Label(app.shortTitle, systemImage: app.symbol)
                            .font(.caption.weight(.semibold))
                            .frame(maxWidth: .infinity).padding(.vertical, 11)
                            .foregroundStyle(store.selectedApp == app ? Color.white : Color.primary)
                            .background(store.selectedApp == app ? Color.accentColor : Color(.secondarySystemBackground), in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Open \(app.title)")
                }
            }
            .padding(.horizontal, 12).padding(.vertical, 10)
            HStack(spacing: 5) {
                Image(systemName: "sparkles")
                Text("FICTIONAL DEMO · CONTEXT UPDATES AS YOU SCROLL")
            }
            .font(.system(size: 9, weight: .semibold)).tracking(0.6)
            .foregroundStyle(.secondary).padding(.bottom, 9)
            Group {
                switch store.selectedApp {
                case .safari: reader
                case .social: feed
                case .reels: reels
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(.systemBackground))
    }

    private var reader: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "textformat.size")
                Spacer()
                Label("fieldnotes.example / focus", systemImage: "lock.fill")
                    .font(.caption)
                Spacer()
                Image(systemName: "arrow.clockwise")
            }
            .padding(14).background(Color(.secondarySystemBackground))
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 32) {
                    ForEach(DemoContent.article.indices, id: \.self) { index in
                        VStack(alignment: .leading, spacing: 18) {
                            if index == 0 {
                                Text("FIELD NOTES").font(.caption.weight(.bold)).tracking(3)
                                    .foregroundStyle(Color.accentColor)
                                Image(systemName: "figure.walk")
                                    .font(.system(size: 72, weight: .ultraLight))
                                    .frame(maxWidth: .infinity).frame(height: 135)
                                    .background(Color.accentColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 22))
                            }
                            let parts = DemoContent.article[index].split(separator: "\n", maxSplits: 1)
                            Text(String(parts[0]))
                                .font(.system(index == 0 ? .largeTitle : .title2, design: .serif, weight: .semibold))
                            Text(String(parts[1])).font(.system(.body, design: .serif)).lineSpacing(7)
                            if index == 2 {
                                Text("Fictional article for the DuoSync demo. No real study is cited.")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        .id(index)
                    }
                }
                .scrollTargetLayout()
                .padding(24).padding(.bottom, 90)
            }
            .scrollPosition(id: $visibleArticle, anchor: .top)
            .onChange(of: visibleArticle) { _, index in
                if let index { store.recordVisible(DemoContent.article[index], in: .safari) }
            }
            .onAppear {
                store.recordVisible(DemoContent.article[visibleArticle ?? 0], in: .safari)
            }
            HStack { Image(systemName: "chevron.left"); Spacer(); Image(systemName: "square.and.arrow.up"); Spacer(); Image(systemName: "book"); Spacer(); Image(systemName: "square.on.square") }
                .foregroundStyle(.blue).padding(16).background(.bar)
                .accessibilityHidden(true)
        }
    }

    private var feed: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "person.crop.circle.fill").foregroundStyle(.gray)
                Spacer(); Text("For you").font(.headline); Spacer()
                Image(systemName: "sparkle")
            }.padding(16)
            Rectangle().fill(Color.blue).frame(width: 64, height: 3)
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(DemoContent.posts.indices, id: \.self) { index in
                        let post = DemoContent.posts[index]
                        VStack(alignment: .leading, spacing: 15) {
                            HStack(spacing: 10) {
                                Text(String(post.name.prefix(1))).font(.headline)
                                    .frame(width: 40, height: 40)
                                    .background(Color.blue.opacity(0.12), in: Circle())
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(post.name).font(.subheadline.weight(.bold))
                                    Text(post.handle + " · Demo").font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "ellipsis").foregroundStyle(.secondary)
                            }
                            Text(post.text).font(.body).lineSpacing(4)
                            Text(post.tag).font(.caption).foregroundStyle(.secondary)
                                .padding(12).frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
                            HStack {
                                Label("12", systemImage: "bubble.left")
                                Spacer()
                                Button { toggle(index, in: &liked) } label: {
                                    Label(liked.contains(index) ? "129" : "128", systemImage: liked.contains(index) ? "heart.fill" : "heart")
                                }.foregroundStyle(liked.contains(index) ? .pink : .secondary)
                                Spacer()
                                Button { toggle(index, in: &saved) } label: {
                                    Image(systemName: saved.contains(index) ? "bookmark.fill" : "bookmark")
                                }.accessibilityLabel(saved.contains(index) ? "Unsave demo post" : "Save demo post")
                            }
                            .font(.caption).foregroundStyle(.secondary).buttonStyle(.plain)
                        }
                        .padding(20).frame(minHeight: 280, alignment: .top)
                        .id(index)
                        Divider()
                    }
                }.scrollTargetLayout().padding(.bottom, 90)
            }
            .scrollPosition(id: $visiblePost, anchor: .top)
            .onChange(of: visiblePost) { _, index in
                if let index { updatePost(index) }
            }
            .onAppear { updatePost(visiblePost ?? 0) }
        }
    }

    private var reels: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 0) {
                ForEach(DemoContent.reels.indices, id: \.self) { index in
                    let reel = DemoContent.reels[index]
                    ZStack {
                        LinearGradient(colors: reel.colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                        VStack(spacing: 24) {
                            Text("REELS / DEMO").font(.caption.weight(.bold)).tracking(3)
                            Spacer()
                            Image(systemName: reel.symbol).font(.system(size: 95, weight: .ultraLight))
                                .shadow(color: .white.opacity(0.3), radius: 30)
                            Text(reel.title).font(.system(.largeTitle, design: .rounded, weight: .black))
                                .multilineTextAlignment(.center)
                            Text("ORIGINAL DEMO ILLUSTRATION").font(.system(size: 9, weight: .bold)).tracking(2)
                            Spacer()
                            HStack(alignment: .bottom, spacing: 18) {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("@curious.demo").font(.headline)
                                    Text(reel.caption).font(.subheadline).lineSpacing(3)
                                    Text("Fictional caption · no source attached")
                                        .font(.caption2).foregroundStyle(.white.opacity(0.7))
                                }
                                VStack(spacing: 24) {
                                    Button { toggle(index + 100, in: &liked) } label: {
                                        Image(systemName: liked.contains(index + 100) ? "heart.fill" : "heart")
                                            .foregroundStyle(liked.contains(index + 100) ? .pink : .white)
                                    }.accessibilityLabel("Like demo reel")
                                    Button { toggle(index + 100, in: &saved) } label: {
                                        Image(systemName: saved.contains(index + 100) ? "bookmark.fill" : "bookmark")
                                    }.accessibilityLabel("Save demo reel")
                                }.font(.title2).buttonStyle(.plain)
                            }
                        }
                        .padding(24).padding(.bottom, 76)
                    }
                    .foregroundStyle(.white)
                    .containerRelativeFrame(.vertical)
                    .id(index)
                }
            }.scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $visibleReel)
        .scrollIndicators(.hidden)
        .onChange(of: visibleReel) { _, index in
            if let index { store.recordVisible(DemoContent.reelText(index), in: .reels) }
        }
        .onAppear { store.recordVisible(DemoContent.reelText(visibleReel ?? 0), in: .reels) }
    }

    private func updatePost(_ index: Int) {
        let post = DemoContent.posts[index]
        store.recordVisible("\(post.name) \(post.handle)\n\(post.text)\n\(post.tag)", in: .social)
    }

    private func toggle(_ index: Int, in set: inout Set<Int>) {
        if set.contains(index) { set.remove(index) } else { set.insert(index) }
    }
}
