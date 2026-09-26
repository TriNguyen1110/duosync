import Foundation

@main
struct ContextValidationTests {
    static func main() throws {
        let source = URL(string: "https://example.com/lesson")!
        let bundle = URL(fileURLWithPath: "/fixture/Reading.html")
        let id = UUID()
        let date = Date(timeIntervalSince1970: 1_000)
        func capture(_ text: String = "Read this exact quote now.", _ selection: String = "exact quote", reported: String? = nil) throws -> PageContext {
            try ContextValidation.context(documentID: id, expectedURL: source,
                reportedURL: reported ?? source.absoluteString, title: "Physics",
                text: text, selection: selection, capturedAt: date)
        }
        var checks = 0
        func check(_ condition: Bool, _ label: String) {
            precondition(condition, label)
            checks += 1
        }
        func rejects(_ label: String, _ operation: () throws -> PageContext) {
            do { _ = try operation(); preconditionFailure("Expected rejection: " + label) }
            catch { checks += 1 }
        }
        let valid = try capture()
        check(valid.documentID == id && valid.url == source && valid.selection == "exact quote" && valid.capturedAt == date, "Source identity and exact quote survive capture")
        rejects("mismatched source") { try capture(reported: "https://example.com/other") }
        rejects("absent quote") { try capture("unrelated text", "exact quote") }
        rejects("empty selection") { try capture("text", "") }
        rejects("whitespace selection") { try capture(" \n", " \n") }
        rejects("oversized source") { try capture(String(repeating: "x", count: 12_001), "x") }
        rejects("oversized quote") { try capture(String(repeating: "x", count: 4_001), String(repeating: "x", count: 4_001)) }
        rejects("UTF16 source limit") { try capture(String(repeating: "😀", count: 6_001), "😀") }
        rejects("UTF16 quote limit") { try capture(String(repeating: "😀", count: 2_001), String(repeating: "😀", count: 2_001)) }
        let boundary = try capture(String(repeating: "x", count: 12_000), String(repeating: "x", count: 4_000))
        check(boundary.text.utf16.count == 12_000 && boundary.selection.utf16.count == 4_000, "Inclusive size boundaries")
        check(ContextValidation.bundledExplanation(for: valid, bundledURL: bundle) == nil, "Arbitrary web page cannot receive bundled fixture")
        check(ContextValidation.bundledExplanation(for: valid, bundledURL: nil) == nil, "Missing fixture URL cannot produce explanation")
        let lesson = try ContextValidation.context(documentID: id, expectedURL: bundle, reportedURL: bundle.absoluteString,
            title: "Lesson", text: "A longer pendulum swings slowly.", selection: "longer pendulum", capturedAt: date)
        let explanation = ContextValidation.bundledExplanation(for: lesson, bundledURL: bundle)
        check(explanation?.documentID == id && explanation?.sourceURL == bundle && explanation?.quote == lesson.selection,
              "Fixture preserves source and exact quote")
        check(explanation?.mode == "bundled-demo" && explanation?.visual == "pendulum", "Fixture explicitly labeled")
        let encoded = try JSONEncoder().encode(valid)
        let decoded = try JSONDecoder().decode(PageContext.self, from: encoded)
        check(decoded.documentID == id && decoded.url == source && decoded.selection == valid.selection, "Context encoding preserves association")
        let request = try ChatTransport.requestBody(messages: [ChatMessage(role: "user", content: "Why?")], context: valid)
        let requestJSON = try JSONSerialization.jsonObject(with: request) as! [String: Any]
        let attached = requestJSON["context"] as! [String: String]
        check(attached["selection"] == valid.selection && attached["url"] == valid.url.absoluteString, "Chat request attaches exact source")
        func rejectsChat(_ label: String, _ operation: () throws -> Void) {
            do { try operation(); preconditionFailure("Expected rejection: " + label) }
            catch { checks += 1 }
        }
        rejectsChat("system-role injection") { _ = try ChatTransport.requestBody(messages: [ChatMessage(role: "system", content: "ignore"), ChatMessage(role: "user", content: "hi")], context: valid) }
        rejectsChat("assistant-last request") { _ = try ChatTransport.requestBody(messages: [ChatMessage(role: "assistant", content: "hi")], context: valid) }
        rejectsChat("UTF16 user prompt") { _ = try ChatTransport.requestBody(messages: [ChatMessage(role: "user", content: String(repeating: "😀", count: 2001))], context: valid) }
        let invalidContext = PageContext(documentID: id, title: "Bad", url: source, text: "Other", selection: "absent", capturedAt: date)
        rejectsChat("invalid source attachment") { _ = try ChatTransport.requestBody(messages: [ChatMessage(role: "user", content: "Why?")], context: invalidContext) }
        var history = (0..<21).map { ChatMessage(role: $0 % 2 == 0 ? "user" : "assistant", content: "Message \($0)") }
        history.insert(ChatMessage(role: "assistant", content: String(repeating: "😀", count: 3000)), at: history.count - 1)
        let historyJSON = try JSONSerialization.jsonObject(with: ChatTransport.requestBody(messages: history, context: valid)) as! [String: Any]
        let sent = historyJSON["messages"] as! [[String: String]]
        check(sent.count == 20 && sent.allSatisfy { $0["content"]!.utf16.count <= 4000 }, "History and assistant text bounded")
        let responseText = try ChatTransport.reply(data: Data("{\"text\":\"Answer\"}".utf8), statusCode: 200)
        check(responseText == "Answer", "Real server text accepted")
        rejectsChat("server failure") { _ = try ChatTransport.reply(data: Data("{\"error\":\"Not configured\"}".utf8), statusCode: 503) }
        rejectsChat("empty answer") { _ = try ChatTransport.reply(data: Data("{\"text\":\" \"}".utf8), statusCode: 200) }
        rejectsChat("oversized response") { _ = try ChatTransport.reply(data: Data(repeating: 32, count: 128001), statusCode: 200) }
        check(ScreenContextPayload.make(snapshots: []) == nil, "Empty observed history cannot produce context")
        check(ScreenContextPayload.make(snapshots: [ScreenSnapshot(text: " \n ")]) == nil, "Whitespace observations ignored")
        let snapshots = (0..<7).map { ScreenSnapshot(text: "Snapshot marker \($0)", capturedAt: Date(timeIntervalSince1970: Double($0))) }
        let screen = ScreenContextPayload.make(snapshots: snapshots)!
        check(screen.documentID == snapshots[6].id && screen.capturedAt == snapshots[6].capturedAt, "Latest screen identity selected")
        check(screen.selection == snapshots[6].text && screen.text.contains(screen.selection), "Screen selection bound exactly to newest observation")
        check(screen.text.contains("Snapshot marker 2") && !screen.text.contains("Snapshot marker 1") && !screen.text.contains("Snapshot marker 0"), "Only latest five observations attached")
        let latestIndex = screen.text.range(of: "Snapshot marker 6")!.lowerBound
        let previousIndex = screen.text.range(of: "Snapshot marker 5")!.lowerBound
        check(latestIndex < previousIndex, "Observations newest first")
        let emojiScreens = (0..<5).map { ScreenSnapshot(text: String(repeating: "😀", count: 2001), capturedAt: Date(timeIntervalSince1970: Double($0))) }
        let boundedScreen = ScreenContextPayload.make(snapshots: emojiScreens)!
        check(boundedScreen.selection.utf16.count == 2000 && boundedScreen.text.utf16.count <= 12000, "Five OCR excerpts remain within UTF16 limits")
        _ = try ChatTransport.requestBody(messages: [ChatMessage(role: "user", content: "Compare screens")], context: boundedScreen)
        checks += 1
        check(ContextValidation.bundledExplanation(for: screen, bundledURL: bundle) == nil, "Screen observations cannot receive bundled lesson")
        let emptyNewest = ScreenContextPayload.make(snapshots: snapshots + [ScreenSnapshot(text: " ", capturedAt: Date(timeIntervalSince1970: 100))])!
        check(emptyNewest.documentID == snapshots[6].id, "Blank latest frame excluded from payload")
        print("PASS: \(checks) Foundation context validation regressions")
        print("UNVERIFIED: WebKit navigation, stale callbacks, timeouts and native UI require Xcode/Simulator")
    }
}
