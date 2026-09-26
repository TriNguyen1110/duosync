import Foundation

struct PageContext: Codable {
    let documentID: UUID
    let title: String
    let url: URL
    let text: String
    let selection: String
    let capturedAt: Date
}

struct Explanation: Codable {
    let documentID: UUID
    let sourceURL: URL
    let quote: String
    let explanation: String
    let mode: String
    let visual: String?
}

/// Foundation-only boundary so source validation can be exercised without WebKit.
enum ContextValidation {
    static let textLimit = 12_000
    static let selectionLimit = 4_000

    enum Failure: LocalizedError {
        case invalidSource, emptySelection, selectionTooLong, selectionNotInSource

        var errorDescription: String? {
            switch self {
            case .invalidSource:
                return "The page changed or could not be read. Select text on the current page and try again."
            case .emptySelection:
                return "Select a sentence in the reading page, then tap Explore selection."
            case .selectionTooLong:
                return "Select a shorter passage (up to 4,000 characters) and try again."
            case .selectionNotInSource:
                return "The selection isn't in the captured page text. Capture is limited to the first 12,000 characters; select an earlier passage."
            }
        }
    }

    static func context(documentID: UUID, expectedURL: URL, reportedURL: String,
                        title: String, text: String, selection: String,
                        capturedAt: Date = Date()) throws -> PageContext {
        guard let sourceURL = URL(string: reportedURL), sourceURL == expectedURL,
              ["http", "https", "file"].contains(sourceURL.scheme?.lowercased() ?? ""),
              text.utf16.count <= textLimit else { throw Failure.invalidSource }
        guard !selection.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw Failure.emptySelection
        }
        guard selection.utf16.count <= selectionLimit else { throw Failure.selectionTooLong }
        guard text.contains(selection) else { throw Failure.selectionNotInSource }
        return PageContext(documentID: documentID, title: String(title.prefix(300)),
                           url: sourceURL, text: text, selection: selection, capturedAt: capturedAt)
    }

    static func bundledExplanation(for context: PageContext, bundledURL: URL?) -> Explanation? {
        guard let bundledURL, context.url == bundledURL,
              context.text.contains(context.selection), !context.selection.isEmpty else { return nil }
        return Explanation(documentID: context.documentID, sourceURL: context.url,
                           quote: context.selection,
                           explanation: "This bundled lesson illustrates the small-angle pendulum model. A longer string gives a slower swing: the period grows with the square root of the length. Doubling the length increases the period by √2 (about 1.41), rather than doubling it. Adjust the length below to explore the model. This is a prewritten lesson, not an AI interpretation of your selected passage.",
                           mode: "bundled-demo", visual: "pendulum")
    }
}
