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
        print("PASS: \(checks) Foundation context validation regressions")
        print("UNVERIFIED: WebKit navigation, stale callbacks, timeouts and native UI require Xcode/Simulator")
    }
}
