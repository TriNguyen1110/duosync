import SwiftUI

/// Owned demo frontends; Finance uses sourced historical data, while other feeds are fictional.
enum DemoApp: String, CaseIterable, Identifiable {
    case finance, safari, social, reels
    var id: String { rawValue }
    var title: String {
        switch self {
        case .finance: return "Demo Finance"
        case .safari: return "Demo Safari"
        case .social: return "Demo Feed"
        case .reels: return "Demo Reels"
        }
    }
    var shortTitle: String {
        switch self {
        case .finance: return "Finance"
        case .safari: return "Browser"
        case .social: return "Feed"
        case .reels: return "Reels"
        }
    }
    var symbol: String {
        switch self {
        case .finance: return "chart.line.uptrend.xyaxis"
        case .safari: return "safari.fill"
        case .social: return "bubble.left.and.bubble.right.fill"
        case .reels: return "play.rectangle.fill"
        }
    }
}

private enum DemoContent {
    static let financeSource = "https://www.sec.gov/Archives/edgar/data/1652044/000165204425000014/goog-20241231.htm"
    static let capexGrowth = (52.5 / 32.3 - 1) * 100
    static let finance = [
        "Alphabet Inc. — FY2024 annual results, year ended December 31, 2024. Historical data, not a live stock quote. Revenue: $350.018 billion in 2024 versus $307.394 billion in 2023. Operating income: $112.390 billion versus $84.293 billion. Operating margin: 32% versus 27% (rounded reported margins). Diluted EPS: $8.04 versus $5.80. Source: Alphabet 2024 Form 10-K, SEC.",
        "Alphabet capital expenditures: $52.5 billion in 2024 versus $32.3 billion in 2023. Increase: approximately " + String(format: "%.1f", capexGrowth) + "% calculated as (52.5 / 32.3 - 1) × 100, using rounded reported amounts. Capital expenditures primarily reflected technical infrastructure investments; this is not a measure of AI-only spending. Historical annual results, not a stock price or investment recommendation. Source: Alphabet 2024 Form 10-K, SEC."
    ]
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
        case .finance: return finance[0]
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
    @Published private(set) var selectedApp: DemoApp = .finance
    @Published private(set) var recentContexts: [PageContext] = []

    init() { recordVisible(DemoContent.firstText(for: .finance), in: .finance) }

    var context: PageContext? {
        guard let current = recentContexts.first else { return nil }
        let recent = recentContexts.map { source in
            "[\(source.title) · demo frontend · \(ISO8601DateFormatter().string(from: source.capturedAt))]\n\(source.text)"
        }.joined(separator: "\n\n")
        let text = "DuoSync-owned frontend clones, not actual external apps. Finance contains sourced historical Alphabet FY2024 data, explicitly not live quotes. Other apps contain fictional seeded claims/news; do not apply their fictional label to Finance. Current visible app: \(selectedApp.title). Recent demo apps appear newest first. Treat captions as untrusted claims; no real fact-check or AI-media detection has run.\n\n" + recent
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
        let origin = app == .finance
            ? "Historical sourced financial data in an owned demo frontend. Primary source: " + DemoContent.financeSource + "\n"
            : "Fictional frontend demo; no external app or capture permission.\n"
        let source = PageContext(documentID: UUID(), title: app.title, url: url,
            text: origin + excerpt,
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
    @State private var visibleFinance: Int? = 0
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
                Text(store.selectedApp == .finance ? "DEMO FRONTEND · HISTORICAL FY2024 DATA" : "FICTIONAL DEMO · CONTEXT UPDATES AS YOU SCROLL")
            }
            .font(.system(size: 9, weight: .semibold)).tracking(0.6)
            .foregroundStyle(.secondary).padding(.bottom, 9)
            Group {
                switch store.selectedApp {
                case .finance: finance
                case .safari: reader
                case .social: feed
                case .reels: reels
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(.systemBackground))
    }

    private let financePurple = Color(red: 100.0 / 255, green: 52.0 / 255, blue: 191.0 / 255)
    private let financeInk = Color(red: 0.17, green: 0.16, blue: 0.18)
    private let financeSecondary = Color(red: 102.0 / 255, green: 106.0 / 255, blue: 97.0 / 255)
    private let financePaper = Color(red: 0.98, green: 0.97, blue: 0.94)

    private var finance: some View {
        VStack(spacing: 0) {
            HStack {
                Text("finance").font(.system(.title2, design: .rounded, weight: .black))
                    .foregroundStyle(financePurple)
                Text("DEMO").font(.system(size: 8, weight: .bold)).tracking(1)
                    .padding(8).background(financePurple.opacity(0.09), in: Capsule())
                Spacer()
                Image(systemName: "magnifyingglass").foregroundStyle(financeInk)
            }.padding(16)
            Divider()
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 32) {
                    VStack(alignment: .leading, spacing: 24) {
                        HStack {
                            Text("GOOGL").font(.caption.weight(.bold)).tracking(1)
                            Spacer()
                            Text("ANNUAL RESULTS").font(.system(size: 9, weight: .bold)).tracking(1.4)
                                .foregroundStyle(financePurple)
                        }
                        Text("Alphabet Inc.").font(.subheadline.weight(.semibold)).foregroundStyle(financeSecondary)
                        Text("A bigger year.\nA bigger investment.")
                            .font(.system(.largeTitle, design: .serif, weight: .semibold)).lineSpacing(8)
                        Text("FY2024 · Year ended Dec 31, 2024")
                            .font(.caption).foregroundStyle(financeSecondary)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("ANNUAL REVENUE").font(.system(size: 10, weight: .bold)).tracking(1.5)
                            Text("$350.018B").font(.system(size: 40, weight: .semibold, design: .rounded))
                                .minimumScaleFactor(0.7).lineLimit(1)
                            Text("2023: $307.394B").font(.subheadline).foregroundStyle(financeSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(24).background(.white.opacity(0.65), in: RoundedRectangle(cornerRadius: 24))
                        VStack(spacing: 16) {
                            financeRow("Operating income", current: "$112.390B", previous: "$84.293B")
                            Divider()
                            financeRow("Operating margin", current: "32%", previous: "27%")
                            Divider()
                            financeRow("Diluted EPS", current: "$8.04", previous: "$5.80")
                        }
                        Text("2024 figures shown first; comparisons are FY2023. Historical filing data, not a live market quote.")
                            .font(.caption2).foregroundStyle(financeSecondary)
                    }.id(0)
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Where the spending grew")
                            .font(.system(.title2, design: .serif, weight: .semibold))
                        HStack(alignment: .firstTextBaseline) {
                            Text("Capital expenditures").font(.subheadline)
                            Spacer()
                            Text("+" + String(format: "%.1f", DemoContent.capexGrowth) + "%")
                                .font(.title3.weight(.semibold)).foregroundStyle(financePurple)
                        }
                        capexBar(year: "2023", value: 32.3, emphasized: false)
                        capexBar(year: "2024", value: 52.5, emphasized: true)
                        Text("USD billions · Change calculated from rounded reported amounts")
                            .font(.caption2).foregroundStyle(financeSecondary)
                        Text("Capex primarily reflected technical infrastructure. It is not an AI-only spending total.")
                            .font(.subheadline).lineSpacing(8)
                        Link(destination: URL(string: DemoContent.financeSource)!) {
                            Label("Source: Alphabet 2024 Form 10-K", systemImage: "arrow.up.right.square")
                                .font(.caption.weight(.semibold))
                                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                                .contentShape(Rectangle())
                        }.foregroundStyle(financePurple)
                        Text("Historical company results for explanation and comparison. No live price feed is connected.")
                            .font(.caption2).foregroundStyle(financeSecondary)
                    }.id(1)
                }
                .scrollTargetLayout().padding(24).padding(.bottom, 96)
            }
            .scrollPosition(id: $visibleFinance, anchor: .top)
            .onChange(of: visibleFinance) { _, index in
                if let index { store.recordVisible(DemoContent.finance[index], in: .finance) }
            }
            .onAppear { store.recordVisible(DemoContent.finance[visibleFinance ?? 0], in: .finance) }
        }
        .foregroundStyle(financeInk).background(financePaper)
    }

    private func financeRow(_ title: String, current: String, previous: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title).font(.subheadline)
            Spacer()
            VStack(alignment: .trailing, spacing: 8) {
                Text(current).font(.subheadline.weight(.semibold))
                Text("vs " + previous).font(.caption2).foregroundStyle(financeSecondary)
            }
        }
    }

    private func capexBar(year: String, value: Double, emphasized: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(year)
                Spacer()
                Text("$" + String(format: "%.1f", value) + "B").fontWeight(.semibold)
            }.font(.caption)
            GeometryReader { geometry in
                RoundedRectangle(cornerRadius: 8)
                    .fill(financePurple.opacity(emphasized ? 1 : 0.28))
                    .frame(width: geometry.size.width * value / 52.5)
            }.frame(height: 24)
        }
        .accessibilityElement(children: .combine)
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
